import 'package:supabase_flutter/supabase_flutter.dart';
import '../encryption/encryption_service.dart';
import '../storage/app_database.dart';

/// Υπηρεσία συγχρονισμού με Supabase (Postgres + Storage, free tier).
/// Ο πίνακας `notes` στο Supabase αποθηκεύει ΜΟΝΟ ciphertext.
class SupabaseSyncService {
  final SupabaseClient _client;
  final EncryptionService _encryption;
  final AppDatabase _db;

  SupabaseSyncService({
    required SupabaseClient client,
    required EncryptionService encryption,
    required AppDatabase db,
  })  : _client = client,
        _encryption = encryption,
        _db = db;

  Future<void> pushLocalChanges() async {
    final unsyncedNotes = await (_db.select(_db.notes)
          ..where((n) => n.isSynced.equals(false)))
        .get();

    for (final note in unsyncedNotes) {
      await _client.from('notes').upsert({
        'id': note.id,
        'encrypted_content': note.encryptedContent,
        'updated_at': note.updatedAt.toIso8601String(),
        'is_deleted': note.isDeleted,
      });
      await (_db.update(_db.notes)..where((n) => n.id.equals(note.id)))
          .write(const NotesCompanion(isSynced: Value(true)));
    }

    final unsyncedEntries = await (_db.select(_db.dailyEntries)
          ..where((e) => e.isSynced.equals(false)))
        .get();

    for (final entry in unsyncedEntries) {
      await _client.from('daily_entries').upsert({
        'id': entry.id,
        'timestamp': entry.timestamp.toIso8601String(),
        'encrypted_text': entry.encryptedText,
        'tag': entry.tag,
        'weight': entry.weight,
      });
      await (_db.update(_db.dailyEntries)..where((e) => e.id.equals(entry.id)))
          .write(const DailyEntriesCompanion(isSynced: Value(true)));
    }
  }

  Future<void> pullRemoteChanges({required DateTime since}) async {
    final remoteNotes = await _client
        .from('notes')
        .select()
        .gt('updated_at', since.toIso8601String());

    for (final row in remoteNotes as List) {
      await _db.into(_db.notes).insertOnConflictUpdate(
            NotesCompanion.insert(
              id: row['id'] as String,
              title: '',
              encryptedContent: row['encrypted_content'] as String,
              updatedAt: DateTime.parse(row['updated_at'] as String),
              isDeleted: Value(row['is_deleted'] as bool? ?? false),
              isSynced: const Value(true),
            ),
          );
    }

    final remoteEntries = await _client
        .from('daily_entries')
        .select()
        .gt('timestamp', since.toIso8601String());

    for (final row in remoteEntries as List) {
      await _db.into(_db.dailyEntries).insertOnConflictUpdate(
            DailyEntriesCompanion.insert(
              id: row['id'] as String,
              timestamp: DateTime.parse(row['timestamp'] as String),
              encryptedText: row['encrypted_text'] as String,
              tag: Value(row['tag'] as String?),
              weight: Value(row['weight'] as int? ?? 1),
              isSynced: const Value(true),
            ),
          );
    }
  }
}
