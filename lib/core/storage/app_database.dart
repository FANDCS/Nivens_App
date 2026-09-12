import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'app_database.g.dart';

/// Πίνακας σημειώσεων. Το πεδίο [encryptedContent] περιέχει το
/// κρυπτογραφημένο .md αρχείο (front-matter + body) ως bytes (base64 string
/// εδώ για απλότητα). Το plaintext ΔΕΝ αγγίζει ποτέ τη βάση.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()(); // κρατάμε τον τίτλο plaintext τοπικά για γρήγορο search/list, αλλά encrypted στο sync layer
  TextColumn get encryptedContent => text()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Πίνακας attachments (εικόνες, ήχος, βίντεο, ζωγραφιές ως SVG/PNG).
/// Τα ίδια τα bytes αποθηκεύονται κρυπτογραφημένα στο filesystem
/// (βλ. EncryptionService.encryptFile) — εδώ κρατάμε μόνο metadata.
@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get type => text()(); // image | audio | video | drawing
  TextColumn get localPath => text()(); // path προς το encrypted blob
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Πίνακας για το "daily log" feature (FucksGiven-style).
@DataClassName('DailyEntry')
class DailyEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get encryptedText => text()();
  TextColumn get tag => text().nullable()();
  IntColumn get weight => integer().withDefault(const Constant(1))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Δυναμικές κατηγορίες/tags — κοινός πίνακας για notes ('note') και
/// καθημερινά ('daily'), ώστε ο χρήστης να μπορεί να φτιάχνει/σβήνει δικές
/// του κατηγορίες αντί για hardcoded λίστα.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // 'note' | 'daily'

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes, Attachments, DailyEntries, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categories);
          }
        },
      );

  /// Δημιουργεί σύνδεση σε encrypted SQLite (SQLCipher) με το raw key (hex)
  /// που προκύπτει από το EncryptionService.getKeyHex(). Χρήση raw key αντί
  /// για passphrase ώστε να μην ξαναζητείται το passphrase σε κάθε άνοιγμα.
  static QueryExecutor openEncrypted(String keyHex) {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'notes_app.sqlite'));

      return NativeDatabase.createInBackground(
        file,
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = \"x'$keyHex'\";");
        },
      );
    });
  }
}
