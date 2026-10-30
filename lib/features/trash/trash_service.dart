import 'package:drift/drift.dart';
import '../../core/storage/app_database.dart';

/// Λογική του κάδου για τις σημειώσεις.
///
/// Η «διαγραφή» σημείωσης είναι ήδη soft-delete (isDeleted = true). Ως ώρα
/// διαγραφής χρησιμοποιείται το `updatedAt` (ο editor το ενημερώνει τη στιγμή
/// της διαγραφής), άρα δεν χρειάζεται αλλαγή σχήματος βάσης/migration.
class TrashService {
  /// Μέρες παραμονής στον κάδο πριν την αυτόματη οριστική διαγραφή.
  static const int retentionDays = 35;

  final AppDatabase db;
  TrashService(this.db);

  DateTime get _cutoff =>
      DateTime.now().toUtc().subtract(const Duration(days: retentionDays));

  /// Οριστικά διαγράφει ό,τι είναι στον κάδο πάνω από [retentionDays] μέρες.
  /// Να καλείται στην εκκίνηση της εφαρμογής (και όταν ανοίγει ο κάδος).
  Future<int> purgeExpired() {
    return (db.delete(db.notes)
          ..where((n) =>
              n.isDeleted.equals(true) & n.updatedAt.isSmallerThanValue(_cutoff)))
        .go();
  }

  Stream<List<Note>> watchTrashed() {
    return (db.select(db.notes)
          ..where((n) => n.isDeleted.equals(true))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch();
  }

  /// Επαναφορά: η σημείωση ξαναεμφανίζεται στη λίστα. Το updatedAt ανανεώνεται
  /// και το isSynced γίνεται false ώστε να συγχρονιστεί η επαναφορά.
  Future<void> restore(String id) {
    return (db.update(db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> deleteForever(String id) {
    return (db.delete(db.notes)..where((n) => n.id.equals(id))).go();
  }

  Future<void> emptyTrash() {
    return (db.delete(db.notes)..where((n) => n.isDeleted.equals(true))).go();
  }

  /// Πόσες μέρες απομένουν μέχρι την αυτόματη διαγραφή.
  static int daysLeft(DateTime deletedAt) {
    final passed = DateTime.now().toUtc().difference(deletedAt.toUtc()).inDays;
    return (retentionDays - passed).clamp(0, retentionDays);
  }
}
