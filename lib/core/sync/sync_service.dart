import 'package:drift/drift.dart' show Value;

import '../storage/app_database.dart';
import 'crypto_util.dart';
import 'custom_rest_sync_backend.dart';
import 'pocketbase_sync_backend.dart';
import 'sync_backend.dart';
import 'sync_row.dart';
import 'sync_settings_store.dart';
import 'supabase_sync_backend.dart';

class SyncResult {
  final int pushed;
  final int pulled;
  final String? error;
  const SyncResult({this.pushed = 0, this.pulled = 0, this.error});
  bool get ok => error == null;
}

/// Συγχρονίζει Σημειώσεις ([AppDatabase.notes]) και Καθημερινά
/// ([AppDatabase.dailyEntries]) πάνω από το ίδιο pluggable backend
/// (Supabase / PocketBase / Custom REST) που χρησιμοποιεί το Callen.
///
/// Κάθε τοπική εγγραφή γίνεται ΕΝΑ [SyncRow]: το περιεχόμενό της (μαζί με
/// ένα πεδίο `kind` που λέει αν είναι 'note' ή 'daily_entry') κρυπτογραφείται
/// σαν ενιαίο JSON blob πριν φύγει προς το backend - το backend βλέπει
/// πάντα μόνο έναν πίνακα (`sync_entries`) με άσχετα bytes.
class SyncService {
  final SyncSettingsStore store;
  final AppDatabase db;

  SyncService({required this.store, required this.db});

  /// Χτίζει το σωστό backend με βάση τις τρέχουσες ρυθμίσεις.
  /// Πετάει [SyncBackendException] αν λείπουν στοιχεία σύνδεσης.
  SyncBackend buildBackend() {
    final url = store.syncServerUrl.trim();
    final key = store.syncApiKey.trim();
    if (url.isEmpty || key.isEmpty) {
      throw const SyncBackendException(
        'Λείπουν το URL ή το API Key/Token στις ρυθμίσεις συγχρονισμού.',
      );
    }
    switch (store.syncBackend) {
      case 'pocketbase':
        return PocketBaseSyncBackend(baseUrl: url, authToken: key);
      case 'custom':
        return CustomRestSyncBackend(baseUrl: url, authValue: key);
      case 'supabase':
      default:
        return SupabaseSyncBackend(projectUrl: url, anonKey: key);
    }
  }

  Future<void> testConnection() async {
    await buildBackend().testConnection();
  }

  /// Πλήρης κύκλος: push ό,τι είναι τοπικό & μη-συγχρονισμένο (σημειώσεις +
  /// καθημερινά), μετά pull ό,τι νεότερο υπάρχει στο backend. Ασφαλές να
  /// καλείται συχνά - δεν ξανά-ανεβάζει/κατεβάζει ό,τι έχει ήδη γίνει.
  Future<SyncResult> syncNow() async {
    if (!store.syncEnabled) {
      return const SyncResult(error: 'Ο συγχρονισμός δεν είναι ενεργός.');
    }
    final password = store.syncEncryptionPassword;
    if (password.isEmpty) {
      return const SyncResult(
        error: 'Δεν έχει οριστεί κωδικός συγχρονισμού.',
      );
    }

    late final SyncBackend backend;
    try {
      backend = buildBackend();
    } on SyncBackendException catch (e) {
      return SyncResult(error: e.message);
    }

    var pushed = 0;
    var pulled = 0;

    try {
      final deviceOrigin = await store.ensureSyncDeviceId();
      final now = DateTime.now().toUtc();
      final rows = <SyncRow>[];

      // --- PUSH: σημειώσεις ---
      final unsyncedNotes = await (db.select(db.notes)
            ..where((n) => n.isSynced.equals(false)))
          .get();
      for (final note in unsyncedNotes) {
        final blob = await SyncCrypto.encryptJson({
          'kind': 'note',
          'id': note.id,
          'title': note.title,
          'encryptedContent': note.encryptedContent,
          'updatedAt': note.updatedAt.toIso8601String(),
          'isDeleted': note.isDeleted,
        }, password);
        rows.add(SyncRow(
          entryId: note.id,
          deviceOrigin: deviceOrigin,
          payload: blob,
          updatedAt: now,
        ));
      }

      // --- PUSH: καθημερινά ---
      final unsyncedDaily = await (db.select(db.dailyEntries)
            ..where((e) => e.isSynced.equals(false)))
          .get();
      for (final entry in unsyncedDaily) {
        final blob = await SyncCrypto.encryptJson({
          'kind': 'daily_entry',
          'id': entry.id,
          'timestamp': entry.timestamp.toIso8601String(),
          'encryptedText': entry.encryptedText,
          'tag': entry.tag,
          'weight': entry.weight,
        }, password);
        rows.add(SyncRow(
          entryId: entry.id,
          deviceOrigin: deviceOrigin,
          payload: blob,
          updatedAt: now,
        ));
      }

      if (rows.isNotEmpty) {
        // Batches των 50 ώστε ένα μεγάλο πρώτο sync να μην κάνει ένα
        // τεράστιο request.
        for (var i = 0; i < rows.length; i += 50) {
          final chunk = rows.sublist(i, i + 50 > rows.length ? rows.length : i + 50);
          await backend.pushRows(chunk);
        }
        if (unsyncedNotes.isNotEmpty) {
          await (db.update(db.notes)
                ..where((n) => n.id.isIn(unsyncedNotes.map((n) => n.id))))
              .write(const NotesCompanion(isSynced: Value(true)));
        }
        if (unsyncedDaily.isNotEmpty) {
          await (db.update(db.dailyEntries)
                ..where((e) => e.id.isIn(unsyncedDaily.map((e) => e.id))))
              .write(const DailyEntriesCompanion(isSynced: Value(true)));
        }
        pushed = rows.length;
      }

      // --- PULL ---
      final since = store.syncLastPulledAt;
      final remoteRows = await backend.pullRows(since);
      DateTime? maxUpdatedAt = since;
      for (final row in remoteRows) {
        try {
          final json = await SyncCrypto.decryptJson(row.payload, password);
          switch (json['kind'] as String?) {
            case 'note':
              await db.into(db.notes).insertOnConflictUpdate(
                    NotesCompanion.insert(
                      id: json['id'] as String,
                      title: json['title'] as String? ?? '',
                      encryptedContent: json['encryptedContent'] as String,
                      updatedAt: DateTime.parse(json['updatedAt'] as String),
                      isDeleted: Value(json['isDeleted'] as bool? ?? false),
                      isSynced: const Value(true),
                    ),
                  );
              break;
            case 'daily_entry':
              await db.into(db.dailyEntries).insertOnConflictUpdate(
                    DailyEntriesCompanion.insert(
                      id: json['id'] as String,
                      timestamp: DateTime.parse(json['timestamp'] as String),
                      encryptedText: json['encryptedText'] as String,
                      tag: Value(json['tag'] as String?),
                      weight: Value(json['weight'] as int? ?? 1),
                      isSynced: const Value(true),
                    ),
                  );
              break;
            default:
              // Άγνωστος τύπος (π.χ. από νεότερη έκδοση της εφαρμογής) -
              // τον αγνοούμε αντί να σκάσουμε όλο το sync.
              break;
          }
          pulled++;
        } on SyncDecryptionException {
          // Λάθος κωδικός ή αλλοιωμένη εγγραφή - την αγνοούμε, δεν
          // σταματάμε όλο το sync εξαιτίας μίας κακής εγγραφής.
          continue;
        }
        if (maxUpdatedAt == null || row.updatedAt.isAfter(maxUpdatedAt)) {
          maxUpdatedAt = row.updatedAt;
        }
      }
      if (maxUpdatedAt != null) {
        await store.setSyncLastPulledAt(maxUpdatedAt);
      }

      return SyncResult(pushed: pushed, pulled: pulled);
    } on SyncBackendException catch (e) {
      return SyncResult(pushed: pushed, pulled: pulled, error: e.message);
    } catch (e) {
      return SyncResult(pushed: pushed, pulled: pulled, error: e.toString());
    }
  }
}
