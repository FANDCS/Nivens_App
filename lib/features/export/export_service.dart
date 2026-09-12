import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import '../../core/storage/nivens_folder.dart';

/// Μορφή εξαγωγής για μία σημείωση.
enum ExportFormat { markdown, json, qr }

/// Δημιουργεί encrypted export αρχεία (.notesbackup): zip στη μνήμη +
/// AES-256-GCM encryption ολόκληρου του zip με κλειδί που παράγεται
/// από τον κωδικό του χρήστη (Argon2id, τυχαίο salt στην αρχή του αρχείου).
///
/// Υποστηρίζει επίσης ελαφρύ (χωρίς zip) encrypted base64 export, για
/// περιεχόμενο που πρέπει να χωρέσει σε QR code.
class ExportService {
  final AesGcm _aesGcm = AesGcm.with256bits();
  static const _magic = 'NAPZ01';

  Future<String> exportEncryptedZip({
    required Map<String, String> files,
    required String password,
    required String outputNamePrefix,
  }) async {
    final archive = Archive();
    files.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final zipBytes = ZipEncoder().encode(archive);

    final salt = SecretKeyData.random(length: 16).bytes;
    final algorithm = Argon2id(parallelism: 4, memory: 64 * 1024, iterations: 3, hashLength: 32);
    final derived = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(zipBytes, secretKey: derived, nonce: nonce);

    final output = BytesBuilder();
    output.add(utf8.encode(_magic));
    output.add(salt);
    output.add(secretBox.concatenation());

    final dir = await _exportDirectory();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, '${outputNamePrefix}_$timestamp.notesbackup'));
    await file.writeAsBytes(output.toBytes());
    return file.path;
  }

  Future<Map<String, String>> decryptExportedZip({
    required Uint8List fileBytes,
    required String password,
  }) async {
    final magicBytes = utf8.encode(_magic);
    if (fileBytes.length < magicBytes.length + 16 + 12) {
      throw const FormatException('Μη έγκυρο αρχείο backup.');
    }
    var offset = magicBytes.length;
    final salt = fileBytes.sublist(offset, offset + 16);
    offset += 16;
    final rest = fileBytes.sublist(offset);

    final algorithm = Argon2id(parallelism: 4, memory: 64 * 1024, iterations: 3, hashLength: 32);
    final derived = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);

    final secretBox = SecretBox.fromConcatenation(rest, nonceLength: 12, macLength: 16);
    final zipBytes = await _aesGcm.decrypt(secretBox, secretKey: derived);

    final archive = ZipDecoder().decodeBytes(zipBytes);
    final result = <String, String>{};
    for (final f in archive.files) {
      if (f.isFile) {
        result[f.name] = utf8.decode(f.content as List<int>);
      }
    }
    return result;
  }

  /// Ελαφρύ encrypted export (χωρίς zip container) — σχεδιασμένο για QR
  /// codes όπου κάθε byte μετράει. Επιστρέφει base64 string:
  /// salt(16) + nonce(12) + ciphertext+mac.
  Future<String> encryptToBase64({required String content, required String password}) async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final algorithm = Argon2id(parallelism: 4, memory: 64 * 1024, iterations: 3, hashLength: 32);
    final derived = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(utf8.encode(content), secretKey: derived, nonce: nonce);

    final output = BytesBuilder();
    output.add(salt);
    output.add(secretBox.concatenation());
    return base64Encode(output.toBytes());
  }

  Future<String> decryptFromBase64({required String encoded, required String password}) async {
    final bytes = base64Decode(encoded);
    final salt = bytes.sublist(0, 16);
    final rest = bytes.sublist(16);

    final algorithm = Argon2id(parallelism: 4, memory: 64 * 1024, iterations: 3, hashLength: 32);
    final derived = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);

    final secretBox = SecretBox.fromConcatenation(rest, nonceLength: 12, macLength: 16);
    final plainBytes = await _aesGcm.decrypt(secretBox, secretKey: derived);
    return utf8.decode(plainBytes);
  }

  /// Απλή, ΜΗ κρυπτογραφημένη εξαγωγή ενός αρχείου (χρησιμοποιείται για τις
  /// επιλογές JSON/Markdown όταν ο χρήστης ΔΕΝ διάλεξε "ZIP με κωδικό").
  Future<String> exportPlainFile({
    required String content,
    required String filename,
  }) async {
    final dir = await _exportDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    return file.path;
  }

  /// Λίστα αρχείων στον φάκελο εξαγωγής, για το Import screen.
  Future<List<File>> listExportedFiles() async {
    final dir = await _exportDirectory();
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => const ['.md', '.json', '.notesbackup', '.txt']
            .any((ext) => f.path.endsWith(ext)))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  }

  /// Όλα τα exports πλέον πηγαίνουν στον φάκελο Documents/Nivens/exports,
  /// ώστε ο χρήστης να τα βρίσκει εύκολα (Files app / File Manager),
  /// αντί για έναν κρυμμένο εσωτερικό φάκελο της εφαρμογής.
  Future<Directory> _exportDirectory() => NivensFolder.sub('exports');
}
