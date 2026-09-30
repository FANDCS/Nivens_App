import 'dart:convert';
import 'dart:typed_data';

/// Κωδικοποιήσεις κειμένου που υποστηρίζονται για εισαγωγή/εξαγωγή/μετατροπή
/// αρχείων. Δεν χρειάζεται εξωτερικό πακέτο: οι πίνακες των μονοψήφιων
/// (single-byte) κωδικοποιήσεων παρήχθησαν από τα επίσημα mappings
/// (Windows-1253/1252/1251, ISO-8859-7) και δίνουν τον Unicode χαρακτήρα για
/// κάθε byte 0x80–0xFF (0xFFFD = απροσδιόριστο byte).
class TextEncoding {
  final String id;
  final String label;
  const TextEncoding._(this.id, this.label);

  static const utf8Enc = TextEncoding._('utf8', 'UTF-8');
  static const utf8Bom = TextEncoding._('utf8bom', 'UTF-8 (BOM)');
  static const utf16le = TextEncoding._('utf16le', 'UTF-16 LE');
  static const utf16be = TextEncoding._('utf16be', 'UTF-16 BE');
  static const cp1253 = TextEncoding._('cp1253', 'Windows-1253 (Greek)');
  static const iso88597 = TextEncoding._('iso88597', 'ISO-8859-7 (Greek)');
  static const cp1252 = TextEncoding._('cp1252', 'Windows-1252 (Western)');
  static const latin1 = TextEncoding._('latin1', 'ISO-8859-1 (Latin-1)');
  static const cp1251 = TextEncoding._('cp1251', 'Windows-1251 (Cyrillic)');

  static const all = <TextEncoding>[
    utf8Enc, utf8Bom, utf16le, utf16be, cp1253, iso88597, cp1252, latin1, cp1251,
  ];

  static TextEncoding? byId(String? id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  String toString() => label;
}

class TextCodecs {
  TextCodecs._();

  static const _replacement = 0xFFFD;

  static const List<int> _cp1253Table = [
    0x20AC, 0xFFFD, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
    0xFFFD, 0x2030, 0xFFFD, 0x2039, 0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD,
    0xFFFD, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0xFFFD, 0x2122, 0xFFFD, 0x203A, 0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD,
    0x00A0, 0x0385, 0x0386, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0xFFFD, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x2015,
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x0384, 0x00B5, 0x00B6, 0x00B7,
    0x0388, 0x0389, 0x038A, 0x00BB, 0x038C, 0x00BD, 0x038E, 0x038F,
    0x0390, 0x0391, 0x0392, 0x0393, 0x0394, 0x0395, 0x0396, 0x0397,
    0x0398, 0x0399, 0x039A, 0x039B, 0x039C, 0x039D, 0x039E, 0x039F,
    0x03A0, 0x03A1, 0xFFFD, 0x03A3, 0x03A4, 0x03A5, 0x03A6, 0x03A7,
    0x03A8, 0x03A9, 0x03AA, 0x03AB, 0x03AC, 0x03AD, 0x03AE, 0x03AF,
    0x03B0, 0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7,
    0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BE, 0x03BF,
    0x03C0, 0x03C1, 0x03C2, 0x03C3, 0x03C4, 0x03C5, 0x03C6, 0x03C7,
    0x03C8, 0x03C9, 0x03CA, 0x03CB, 0x03CC, 0x03CD, 0x03CE, 0xFFFD,
  ];
  static const List<int> _iso88597Table = [
    0x0080, 0x0081, 0x0082, 0x0083, 0x0084, 0x0085, 0x0086, 0x0087,
    0x0088, 0x0089, 0x008A, 0x008B, 0x008C, 0x008D, 0x008E, 0x008F,
    0x0090, 0x0091, 0x0092, 0x0093, 0x0094, 0x0095, 0x0096, 0x0097,
    0x0098, 0x0099, 0x009A, 0x009B, 0x009C, 0x009D, 0x009E, 0x009F,
    0x00A0, 0x2018, 0x2019, 0x00A3, 0x20AC, 0x20AF, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0x037A, 0x00AB, 0x00AC, 0x00AD, 0xFFFD, 0x2015,
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x0384, 0x0385, 0x0386, 0x00B7,
    0x0388, 0x0389, 0x038A, 0x00BB, 0x038C, 0x00BD, 0x038E, 0x038F,
    0x0390, 0x0391, 0x0392, 0x0393, 0x0394, 0x0395, 0x0396, 0x0397,
    0x0398, 0x0399, 0x039A, 0x039B, 0x039C, 0x039D, 0x039E, 0x039F,
    0x03A0, 0x03A1, 0xFFFD, 0x03A3, 0x03A4, 0x03A5, 0x03A6, 0x03A7,
    0x03A8, 0x03A9, 0x03AA, 0x03AB, 0x03AC, 0x03AD, 0x03AE, 0x03AF,
    0x03B0, 0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7,
    0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BE, 0x03BF,
    0x03C0, 0x03C1, 0x03C2, 0x03C3, 0x03C4, 0x03C5, 0x03C6, 0x03C7,
    0x03C8, 0x03C9, 0x03CA, 0x03CB, 0x03CC, 0x03CD, 0x03CE, 0xFFFD,
  ];
  static const List<int> _cp1252Table = [
    0x20AC, 0xFFFD, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0xFFFD, 0x017D, 0xFFFD,
    0xFFFD, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0xFFFD, 0x017E, 0x0178,
    0x00A0, 0x00A1, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF,
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
    0x00B8, 0x00B9, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF,
    0x00C0, 0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x00C7,
    0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF,
    0x00D0, 0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x00D5, 0x00D6, 0x00D7,
    0x00D8, 0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x00DD, 0x00DE, 0x00DF,
    0x00E0, 0x00E1, 0x00E2, 0x00E3, 0x00E4, 0x00E5, 0x00E6, 0x00E7,
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF,
    0x00F0, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F5, 0x00F6, 0x00F7,
    0x00F8, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x00FD, 0x00FE, 0x00FF,
  ];
  static const List<int> _cp1251Table = [
    0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021,
    0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
    0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0xFFFD, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
    0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
    0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
    0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
    0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
    0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417,
    0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F,
    0x0420, 0x0421, 0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427,
    0x0428, 0x0429, 0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F,
    0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
    0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
    0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
    0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
  ];

  static List<int>? _tableFor(TextEncoding e) {
    if (e == TextEncoding.cp1253) return _cp1253Table;
    if (e == TextEncoding.iso88597) return _iso88597Table;
    if (e == TextEncoding.cp1252) return _cp1252Table;
    if (e == TextEncoding.cp1251) return _cp1251Table;
    return null; // latin1 = ταυτοτικό, οι υπόλοιπες είναι Unicode
  }

  static final Map<TextEncoding, Map<int, int>> _reverse = {};

  // ── Έλεγχοι / ανίχνευση ───────────────────────────────────────────────

  static bool isValidUtf8(Uint8List bytes) {
    try {
      const Utf8Decoder(allowMalformed: false).convert(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Μαντεύει την κωδικοποίηση. Σειρά: BOM → έγκυρο UTF-8 → UTF-16 χωρίς BOM
  /// (πολλά μηδενικά bytes) → παλιά μονοψήφια κωδικοποίηση (ελληνικά
  /// Windows-1253 αν τα bytes ≥0x80 εμφανίζονται σε ομάδες, αλλιώς
  /// Windows-1252). Δεν είναι αλάνθαστο — ο χρήστης μπορεί να το αλλάξει.
  static TextEncoding detect(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      return TextEncoding.utf8Bom;
    }
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return TextEncoding.utf16le;
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return TextEncoding.utf16be;
    if (isValidUtf8(b)) return TextEncoding.utf8Enc;

    if (b.length >= 4) {
      var evenZero = 0, oddZero = 0;
      for (var i = 0; i < b.length; i++) {
        if (b[i] == 0) {
          if (i.isEven) {
            evenZero++;
          } else {
            oddZero++;
          }
        }
      }
      final half = b.length / 2;
      if (oddZero > half * 0.3 && evenZero < half * 0.05) return TextEncoding.utf16le;
      if (evenZero > half * 0.3 && oddZero < half * 0.05) return TextEncoding.utf16be;
    }

    var high = 0, inRuns = 0;
    for (var i = 0; i < b.length; i++) {
      if (b[i] >= 0x80) {
        high++;
        final prev = i > 0 && b[i - 1] >= 0x80;
        final next = i + 1 < b.length && b[i + 1] >= 0x80;
        if (prev || next) inRuns++;
      }
    }
    if (high > 0 && inRuns / high >= 0.6) return TextEncoding.cp1253;
    return TextEncoding.cp1252;
  }

  // ── Αποκωδικοποίηση ───────────────────────────────────────────────────

  static String decode(Uint8List bytes, TextEncoding enc) {
    if (enc == TextEncoding.utf8Enc || enc == TextEncoding.utf8Bom) {
      var start = 0;
      if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        start = 3;
      }
      return utf8.decode(bytes.sublist(start), allowMalformed: true);
    }
    if (enc == TextEncoding.utf16le || enc == TextEncoding.utf16be) {
      final be = enc == TextEncoding.utf16be;
      var start = 0;
      if (bytes.length >= 2) {
        if (!be && bytes[0] == 0xFF && bytes[1] == 0xFE) start = 2;
        if (be && bytes[0] == 0xFE && bytes[1] == 0xFF) start = 2;
      }
      final units = <int>[];
      for (var i = start; i + 1 < bytes.length; i += 2) {
        units.add(be ? (bytes[i] << 8) | bytes[i + 1] : (bytes[i + 1] << 8) | bytes[i]);
      }
      return String.fromCharCodes(units);
    }
    final table = _tableFor(enc);
    final out = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        out.writeCharCode(byte);
      } else if (table == null) {
        out.writeCharCode(byte); // Latin-1
      } else {
        out.writeCharCode(table[byte - 0x80]);
      }
    }
    return out.toString();
  }

  /// Ανίχνευση + αποκωδικοποίηση με ένα βήμα.
  static String decodeAuto(Uint8List bytes) => decode(bytes, detect(bytes));

  // ── Κωδικοποίηση ─────────────────────────────────────────────────────

  /// Χαρακτήρες που δεν υπάρχουν στην κωδικοποίηση-στόχο γίνονται '?'.
  static Uint8List encode(String text, TextEncoding enc) {
    if (enc == TextEncoding.utf8Enc) return Uint8List.fromList(utf8.encode(text));
    if (enc == TextEncoding.utf8Bom) {
      return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]);
    }
    if (enc == TextEncoding.utf16le || enc == TextEncoding.utf16be) {
      final be = enc == TextEncoding.utf16be;
      final units = text.codeUnits;
      final out = BytesBuilder();
      out.add(be ? [0xFE, 0xFF] : [0xFF, 0xFE]);
      for (final u in units) {
        if (be) {
          out.add([(u >> 8) & 0xFF, u & 0xFF]);
        } else {
          out.add([u & 0xFF, (u >> 8) & 0xFF]);
        }
      }
      return out.toBytes();
    }
    final table = _tableFor(enc);
    final reverse = _reverse.putIfAbsent(enc, () {
      final m = <int, int>{};
      if (table != null) {
        for (var i = 0; i < table.length; i++) {
          if (table[i] != _replacement) m[table[i]] = 0x80 + i;
        }
      }
      return m;
    });
    final out = BytesBuilder();
    for (final rune in text.runes) {
      if (rune < 0x80) {
        out.addByte(rune);
      } else if (table == null) {
        out.addByte(rune <= 0xFF ? rune : 0x3F); // Latin-1
      } else {
        out.addByte(reverse[rune] ?? 0x3F);
      }
    }
    return out.toBytes();
  }
}
