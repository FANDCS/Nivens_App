import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Κεντρική υπηρεσία κρυπτογράφησης.
class EncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'master_encryption_key';
  static const _saltStorageKey = 'master_encryption_salt';
  static const _hasPassphraseKey = 'has_passphrase_protection';

  final AesGcm _aesGcm = AesGcm.with256bits();

  SecretKey? _cachedKey;

  /// Καλείται είτε κατά το onboarding (ο χρήστης θέλει προστασία με κωδικό),
  /// είτε αργότερα από τις Ρυθμίσεις αν αποφασίσει να προσθέσει κωδικό.
  Future<void> initializeFromPassphrase(String passphrase) async {
    final algorithm = Argon2id(
      parallelism: 4,
      memory: 64 * 1024, // 64 MB
      iterations: 3,
      hashLength: 32,
    );

    final saltBytes = SecretKeyData.random(length: 16).bytes;

    final derived = await algorithm.deriveKeyFromPassword(
      password: passphrase,
      nonce: saltBytes,
    );

    final keyBytes = await derived.extractBytes();
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
    await _secureStorage.write(key: _saltStorageKey, value: base64Encode(saltBytes));
    await _secureStorage.write(key: _hasPassphraseKey, value: 'true');
    _cachedKey = SecretKey(keyBytes);
  }

  /// Εναλλακτικό αρχικό setup ΧΩΡΙΣ κωδικό: παράγεται τυχαίο κλειδί 256-bit
  /// και αποθηκεύεται απευθείας στο secure storage της συσκευής.
  Future<void> initializeWithRandomKey() async {
    final keyBytes = SecretKeyData.random(length: 32).bytes;
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
    await _secureStorage.write(key: _hasPassphraseKey, value: 'false');
    _cachedKey = SecretKey(keyBytes);
  }

  /// True αν η προστασία βασίζεται σε κωδικό που έχει ορίσει ο χρήστης.
  Future<bool> hasPassphraseProtection() async {
    final value = await _secureStorage.read(key: _hasPassphraseKey);
    return value == 'true';
  }

  Future<SecretKey> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final stored = await _secureStorage.read(key: _keyStorageKey);
    if (stored == null) {
      throw StateError(
          'Δεν έχει γίνει αρχικοποίηση κλειδιού. Κάλεσε initializeFromPassphrase ή initializeWithRandomKey.');
    }
    _cachedKey = SecretKey(base64Decode(stored));
    return _cachedKey!;
  }

  /// True αν έχει ήδη γίνει onboarding σε αυτή τη συσκευή.
  Future<bool> hasKey() async {
    final stored = await _secureStorage.read(key: _keyStorageKey);
    return stored != null;
  }

  /// Το κλειδί σε hex μορφή, έτοιμο για `PRAGMA key = "x'<hex>'"` στο SQLCipher.
  Future<String> getKeyHex() async {
    final key = await _getKey();
    final bytes = await key.extractBytes();
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Κρυπτογραφεί κείμενο (π.χ. ολόκληρο το .md αρχείο μιας σημείωσης).
  Future<String> encryptText(String plainText) async {
    final key = await _getKey();
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return base64Encode(secretBox.concatenation());
  }

  Future<String> decryptText(String encoded) async {
    final key = await _getKey();
    final bytes = base64Decode(encoded);
    final secretBox = SecretBox.fromConcatenation(
      bytes,
      nonceLength: 12,
      macLength: 16,
    );
    final decrypted = await _aesGcm.decrypt(secretBox, secretKey: key);
    return utf8.decode(decrypted);
  }

  /// Κρυπτογραφεί bytes (για attachments: εικόνες, ήχος, βίντεο, ζωγραφιές).
  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final key = await _getKey();
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      plainBytes,
      secretKey: key,
      nonce: nonce,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    final key = await _getKey();
    final secretBox = SecretBox.fromConcatenation(
      encryptedBytes,
      nonceLength: 12,
      macLength: 16,
    );
    final decrypted = await _aesGcm.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(decrypted);
  }
}
