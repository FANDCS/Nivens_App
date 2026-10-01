import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Κεντρικό σημείο αναφοράς για τον φάκελο "Nivens" μέσα στα Documents
/// της συσκευής. Όλες οι εξαγωγές, εικόνες, σχέδια και clip art
/// αποθηκεύονται εδώ, ώστε ο χρήστης να τα βρίσκει εύκολα από το Files app
/// (Android) ή τον File Manager (Linux/Windows), αντί για κρυμμένους
/// φακέλους της εφαρμογής.
class NivensFolder {
  NivensFolder._();

  static Directory? _cached;

  /// Επιστρέφει (δημιουργώντας τον αν χρειάζεται) τον φάκελο:
  ///   Android:  /storage/emulated/0/Documents/Nivens
  ///   Linux/Windows/macOS: <Documents του χρήστη>/Nivens
  /// Αν δεν υπάρχει πρόσβαση στον δημόσιο φάκελο (π.χ. δεν δόθηκε άδεια),
  /// γίνεται fallback στον εσωτερικό φάκελο εγγράφων της εφαρμογής.
  static Future<Directory> root() async {
    if (_cached != null && await _cached!.exists()) return _cached!;

    if (Platform.isAndroid) {
      await _ensureAndroidPermission();
      const publicDocs = '/storage/emulated/0/Documents';
      final dir = Directory(p.join(publicDocs, 'Nivens'));
      try {
        await dir.create(recursive: true);
        _cached = dir;
        return dir;
      } catch (_) {
        // Δεν δόθηκε άδεια / δεν είναι διαθέσιμος ο δημόσιος φάκελος —
        // fallback στον εσωτερικό φάκελο της εφαρμογής.
      }
    }

    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'Nivens'));
    await dir.create(recursive: true);
    _cached = dir;
    return dir;
  }

  /// Υποφάκελος μέσα στο Nivens (π.χ. "images", "drawings", "clipart",
  /// "exports"). Δημιουργείται αν δεν υπάρχει.
  static Future<Directory> sub(String name) async {
    final r = await root();
    final dir = Directory(p.join(r.path, name));
    await dir.create(recursive: true);
    return dir;
  }

  /// Σαν το [sub], αλλά ΕΠΙΠΛΕΟΝ αφήνει ένα κενό αρχείο `.nomedia` μέσα
  /// στον φάκελο — έτσι το Android MediaStore (και άρα η εφαρμογή
  /// Φωτογραφίες/Συλλογή) το ΑΓΝΟΕΙ εντελώς, χωρίς να χρειάζεται να
  /// μετακινήσουμε τα αρχεία σε πλήρως ιδιωτικό (app-private) χώρο —
  /// παραμένουν στο ίδιο εμφανές, "emulated" storage, απλά δεν εμφανίζονται
  /// σαν φωτογραφίες. Χρησιμοποιείται για το "drawings" (οι ζωγραφιές
  /// overlay), ΟΧΙ για "images"/"exports" που ο χρήστης μπορεί να θέλει να
  /// βλέπει στη Συλλογή.
  static Future<Directory> subHidden(String name) async {
    final dir = await sub(name);
    final marker = File(p.join(dir.path, '.nomedia'));
    if (!await marker.exists()) {
      try {
        await marker.writeAsBytes(const []);
      } catch (_) {
        // Best effort — αν αποτύχει (π.χ. σε desktop όπου δεν έχει καν
        // νόημα το .nomedia), συνεχίζουμε κανονικά.
      }
    }
    return dir;
  }

  static Future<void> _ensureAndroidPermission() async {
    try {
      if (await Permission.manageExternalStorage.isGranted) return;
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return;
      // Παλαιότερα Android (<=10): αρκεί το κλασικό WRITE_EXTERNAL_STORAGE.
      await Permission.storage.request();
    } catch (_) {
      // Αν το permission_handler αποτύχει (π.χ. σε desktop build μέσω
      // conditional compilation), απλά προχωράμε — το create() παρακάτω
      // θα αποτύχει με τη σειρά του και θα γίνει fallback.
    }
  }
}
