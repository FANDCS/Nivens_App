import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Ανέβασμα σημείωσης στο https://termbin.com/
///
/// Το termbin είναι ουσιαστικά ένα `netcat` pastebin: ανοίγεις TCP σύνδεση
/// στο termbin.com:9999, στέλνεις το περιεχόμενο, κλείνεις την εγγραφή και
/// ο server απαντά με το URL του paste.
///
/// ΠΡΟΣΟΧΗ (απόρρητο): το termbin είναι **δημόσιο** και χωρίς
/// κρυπτογράφηση — οποιοσδήποτε με το link βλέπει τη σημείωση. Γι' αυτό η
/// εφαρμογή ζητά ρητή επιβεβαίωση πριν το ανέβασμα.
class TermbinService {
  static const host = 'termbin.com';
  static const port = 9999;

  /// Ανεβάζει το [content] και επιστρέφει το URL (π.χ. https://termbin.com/abcd).
  static Future<String> upload(
    String content, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (content.trim().isEmpty) {
      throw const FormatException('Η σημείωση είναι κενή — δεν ανέβηκε τίποτα.');
    }
    // Όριο termbin: ~10 MB. Κόβουμε πολύ νωρίτερα για ασφάλεια.
    final bytes = utf8.encode(content);
    if (bytes.length > 4 * 1024 * 1024) {
      throw const FormatException('Η σημείωση είναι πολύ μεγάλη για το termbin (>4MB).');
    }

    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      // Σηματοδοτούμε τέλος εισόδου — το termbin απαντά μόλις κλείσει το write side.
      await socket.close();

      // Διαβάζουμε την απάντηση byte-by-byte
      final chunks = <int>[];
      await socket.timeout(timeout).forEach(chunks.addAll);
      final response = utf8.decode(chunks, allowMalformed: true);

      final url = _extractUrl(response);
      if (url == null) {
        throw FormatException('Απρόσμενη απάντηση από το termbin: ${response.trim()}');
      }
      return url;
    } on SocketException catch (e) {
      throw Exception('Δεν έγινε σύνδεση στο termbin.com: ${e.message}');
    } on TimeoutException {
      throw Exception('Λήξη χρόνου κατά την επικοινωνία με το termbin.com');
    } finally {
      socket?.destroy();
    }
  }

  static String? _extractUrl(String response) {
    final clean = response.replaceAll('\u0000', '').trim();
    final match = RegExp(r'https?://[^\s]+').firstMatch(clean);
    return match?.group(0);
  }
}
