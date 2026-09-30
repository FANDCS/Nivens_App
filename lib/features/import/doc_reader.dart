import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../core/text_encoding.dart';

/// Ανάγνωση **κειμένου** από παλιά αρχεία Word 97-2003 (.doc), χωρίς
/// εξωτερικό πακέτο.
///
/// Ένα .doc είναι ένα OLE2/CFB container. Διαβάζουμε:
///   1. το stream `WordDocument` (FIB → μήκος κειμένου + θέση του CLX),
///   2. το stream `0Table`/`1Table` (CLX → piece table),
///   3. τα κομμάτια κειμένου (8-bit Windows-1252 ή UTF-16LE) και τα
///      συναρμολογούμε.
///
/// Περιορισμοί (best effort):
///   • Επιστρέφεται μόνο το κείμενο (παράγραφοι + πίνακες ως markdown
///     πίνακες). ΔΕΝ διατηρούνται μορφοποίηση, επικεφαλίδες, λίστες, εικόνες.
///   • Δεν υποστηρίζονται κρυπτογραφημένα .doc ούτε Word 6/95.
class DocReader {
  DocReader._();

  static Future<DocContent> readFile(File file) async {
    final bytes = await file.readAsBytes();
    return DocContent(
      title: p.basenameWithoutExtension(file.path),
      markdown: extractMarkdown(Uint8List.fromList(bytes)),
    );
  }

  /// Επιστρέφει το κείμενο του .doc ως markdown (παράγραφοι + πίνακες).
  static String extractMarkdown(Uint8List data) => _clean(_extractRawText(data));

  // ── FIB / piece table ────────────────────────────────────────────────

  static String _extractRawText(Uint8List data) {
    final cfb = _Cfb.parse(data);
    final wd = cfb.stream('WordDocument');
    if (wd == null || wd.length < 0x1AA) {
      throw const FormatException('Μη έγκυρο .doc — λείπει το stream WordDocument');
    }
    final wdv = ByteData.sublistView(wd);
    if (wdv.getUint16(0, Endian.little) != 0xA5EC) {
      throw const FormatException('Μη έγκυρο .doc — λάθος υπογραφή FIB');
    }
    final nFib = wdv.getUint16(2, Endian.little);
    final flags = wdv.getUint16(0x0A, Endian.little);
    if (flags & 0x0100 != 0) {
      throw const FormatException('Το .doc είναι κρυπτογραφημένο και δεν υποστηρίζεται');
    }
    if (nFib < 0xC1) {
      throw const FormatException(
          'Πολύ παλιά μορφή Word 6/95 — αποθήκευσέ το ως .docx');
    }
    final table = cfb.stream(flags & 0x0200 != 0 ? '1Table' : '0Table');
    if (table == null) {
      throw const FormatException('Μη έγκυρο .doc — λείπει το stream πίνακα');
    }

    final ccpText = wdv.getUint32(0x4C, Endian.little);
    final fcClx = wdv.getUint32(0x1A2, Endian.little);
    final lcbClx = wdv.getUint32(0x1A6, Endian.little);
    if (fcClx + lcbClx > table.length || lcbClx == 0) {
      throw const FormatException('Μη έγκυρο .doc — κατεστραμμένος πίνακας κειμένου');
    }
    final clx = table.sublist(fcClx, fcClx + lcbClx);
    final clxv = ByteData.sublistView(clx);

    // Παράλειψη των Prc (clxt = 0x01) μέχρι το Pcdt (clxt = 0x02).
    var i = 0;
    while (i < clx.length && clx[i] == 1) {
      final cb = clxv.getUint16(i + 1, Endian.little);
      i += 3 + cb;
    }
    if (i + 5 > clx.length || clx[i] != 2) {
      throw const FormatException('Μη έγκυρο .doc — δεν βρέθηκε piece table');
    }
    final lcb = clxv.getUint32(i + 1, Endian.little);
    final plcStart = i + 5;
    if (plcStart + lcb > clx.length) {
      throw const FormatException('Μη έγκυρο .doc — κατεστραμμένη piece table');
    }
    final plc = ByteData.sublistView(clx, plcStart, plcStart + lcb);
    final n = (lcb - 4) ~/ 12;

    final cps = <int>[for (var k = 0; k <= n; k++) plc.getUint32(4 * k, Endian.little)];
    final out = StringBuffer();
    for (var k = 0; k < n; k++) {
      final pcd = 4 * (n + 1) + 8 * k;
      final fc = plc.getUint32(pcd + 2, Endian.little);
      final chars = cps[k + 1] - cps[k];
      if (chars <= 0) continue;
      if (fc & 0x40000000 != 0) {
        // Συμπιεσμένο: 1 byte ανά χαρακτήρα (Windows-1252).
        final off = (fc & 0x3FFFFFFF) ~/ 2;
        if (off >= wd.length) continue;
        final end = off + chars > wd.length ? wd.length : off + chars;
        out.write(TextCodecs.decode(
            Uint8List.sublistView(wd, off, end), TextEncoding.cp1252));
      } else {
        // UTF-16LE.
        if (fc >= wd.length) continue;
        final end = fc + chars * 2 > wd.length ? wd.length : fc + chars * 2;
        final units = <int>[];
        for (var b = fc; b + 1 < end; b += 2) {
          units.add((wd[b + 1] << 8) | wd[b]);
        }
        out.write(String.fromCharCodes(units));
      }
    }
    final all = out.toString();
    return all.length > ccpText ? all.substring(0, ccpText) : all;
  }

  // ── Καθαρισμός / μετατροπή σε markdown ───────────────────────────────

  static String _clean(String text) {
    final blocks = <String>[]; // παράγραφοι και γραμμές πίνακα
    final cur = StringBuffer();
    final cells = <String>[];
    final fieldStack = <bool>[]; // true = κώδικας πεδίου (κρύβεται)
    var rowsInTable = 0;
    var prevWasCellEnd = false;

    void flushParagraph() {
      final s = cur.toString().trim();
      cur.clear();
      rowsInTable = 0;
      blocks.add(s);
    }

    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      // Πεδία: \x13 αρχή, \x14 διαχωριστής, \x15 τέλος.
      if (ch == '\x13') {
        fieldStack.add(true);
        continue;
      }
      if (ch == '\x14') {
        if (fieldStack.isNotEmpty) fieldStack[fieldStack.length - 1] = false;
        continue;
      }
      if (ch == '\x15') {
        if (fieldStack.isNotEmpty) fieldStack.removeLast();
        continue;
      }
      if (fieldStack.contains(true)) continue;

      if (ch == '\x07') {
        // Τέλος κελιού· δύο συνεχόμενα (κενό κελί) = τέλος γραμμής πίνακα.
        if (prevWasCellEnd && cur.isEmpty) {
          if (cells.isNotEmpty) {
            blocks.add('| ${cells.join(' | ')} |');
            if (rowsInTable == 0) {
              blocks.add('|${List.filled(cells.length, ' --- ').join('|')}|');
            }
            rowsInTable++;
            cells.clear();
          }
          prevWasCellEnd = false;
        } else {
          cells.add(cur.toString().trim().replaceAll('|', '/'));
          cur.clear();
          prevWasCellEnd = true;
        }
        continue;
      }
      prevWasCellEnd = false;

      switch (ch) {
        case '\r':
          if (cells.isNotEmpty) {
            cur.write(' '); // αλλαγή παραγράφου μέσα σε κελί
          } else {
            flushParagraph();
          }
          break;
        case '\x0B': // αναγκαστική αλλαγή γραμμής
          cur.write(cells.isNotEmpty ? ' ' : '  \n');
          break;
        case '\x0C': // αλλαγή σελίδας
          flushParagraph();
          break;
        case '\x1E':
          cur.write('-');
          break;
        case '\u00A0':
          cur.write(' ');
          break;
        default:
          // Χαρακτήρες ελέγχου (εικόνες, αντικείμενα κ.λπ.) αγνοούνται.
          if (rune >= 0x20 || rune == 0x09) cur.write(ch);
      }
    }
    if (cur.toString().trim().isNotEmpty) flushParagraph();

    // Οι γραμμές πίνακα μένουν συνεχόμενες, οι παράγραφοι χωρίζονται με
    // κενή γραμμή ώστε το markdown να τις αποδίδει ως ξεχωριστές.
    final result = StringBuffer();
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final isRow = b.startsWith('|');
      final prevIsRow = i > 0 && blocks[i - 1].startsWith('|');
      if (i > 0) {
        result.write(isRow && prevIsRow ? '\n' : '\n\n');
      }
      result.write(b);
    }
    return result
        .toString()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class DocContent {
  final String title;
  final String markdown;
  const DocContent({required this.title, required this.markdown});
}

// ── Ελάχιστος αναγνώστης OLE2 / CFB ────────────────────────────────────

class _Cfb {
  static const _maxRegular = 0xFFFFFFFA;

  final int _miniSize;
  final int _cutoff;
  final List<int> _fat;
  final List<int> _miniFat;
  final Uint8List _miniStream;
  final Map<String, _DirEntry> _entries;
  final Uint8List Function(int start, [int? size]) _readStream;

  _Cfb._(this._miniSize, this._cutoff, this._fat,
      this._miniFat, this._miniStream, this._entries, this._readStream);

  static _Cfb parse(Uint8List data) {
    const sig = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
    if (data.length < 512) {
      throw const FormatException('Μη έγκυρο .doc (πολύ μικρό αρχείο)');
    }
    for (var i = 0; i < 8; i++) {
      if (data[i] != sig[i]) {
        throw const FormatException(
            'Το αρχείο δεν είναι Word 97-2003 (.doc). Αν είναι .docx, άλλαξε την επέκταση.');
      }
    }
    final v = ByteData.sublistView(data);
    final secSize = 1 << v.getUint16(30, Endian.little);
    final miniSize = 1 << v.getUint16(32, Endian.little);
    final numFat = v.getUint32(44, Endian.little);
    final dirStart = v.getUint32(48, Endian.little);
    final cutoff = v.getUint32(56, Endian.little);
    final miniFatStart = v.getUint32(60, Endian.little);
    final numMiniFat = v.getUint32(64, Endian.little);
    final difatStart = v.getUint32(68, Endian.little);
    final numDifat = v.getUint32(72, Endian.little);

    Uint8List sector(int i) {
      final off = (i + 1) * secSize;
      if (off < 0 || off >= data.length) return Uint8List(0);
      final end = off + secSize > data.length ? data.length : off + secSize;
      return Uint8List.sublistView(data, off, end);
    }

    // DIFAT: 109 εγγραφές στην κεφαλίδα + αλυσίδα από sectors.
    final difat = <int>[for (var i = 0; i < 109; i++) v.getUint32(76 + 4 * i, Endian.little)];
    var s = difatStart;
    var count = 0;
    final perSector = secSize ~/ 4 - 1;
    while (s < _maxRegular && count < numDifat) {
      final sec = sector(s);
      if (sec.length < secSize) break;
      final sv = ByteData.sublistView(sec);
      for (var i = 0; i < perSector; i++) {
        difat.add(sv.getUint32(4 * i, Endian.little));
      }
      s = sv.getUint32(4 * perSector, Endian.little);
      count++;
    }

    final fat = <int>[];
    for (var i = 0; i < numFat && i < difat.length; i++) {
      if (difat[i] >= _maxRegular) continue;
      final sec = sector(difat[i]);
      final sv = ByteData.sublistView(sec);
      for (var k = 0; k + 4 <= sec.length; k += 4) {
        fat.add(sv.getUint32(k, Endian.little));
      }
    }

    List<int> chain(int start) {
      final out = <int>[];
      var c = start;
      while (c < _maxRegular && c < fat.length && out.length <= fat.length) {
        out.add(c);
        c = fat[c];
      }
      return out;
    }

    Uint8List readStream(int start, [int? size]) {
      final b = BytesBuilder();
      for (final c in chain(start)) {
        b.add(sector(c));
      }
      final all = b.toBytes();
      return size == null || size >= all.length ? all : Uint8List.sublistView(all, 0, size);
    }

    // Κατάλογος.
    final dir = readStream(dirStart);
    final dv = ByteData.sublistView(dir);
    final entries = <String, _DirEntry>{};
    _DirEntry? root;
    for (var i = 0; (i + 1) * 128 <= dir.length; i++) {
      final base = i * 128;
      final nameLen = dv.getUint16(base + 64, Endian.little);
      final nameBytes = (nameLen - 2).clamp(0, 62);
      final units = <int>[];
      for (var k = 0; k + 1 < nameBytes; k += 2) {
        units.add(dir[base + k] | (dir[base + k + 1] << 8));
      }
      final name = String.fromCharCodes(units);
      final type = dir[base + 66];
      final start = dv.getUint32(base + 116, Endian.little);
      final size = dv.getUint32(base + 120, Endian.little);
      final e = _DirEntry(name, type, start, size);
      if (i == 0) root = e;
      if (type == 2) entries.putIfAbsent(name, () => e);
    }
    if (root == null) {
      throw const FormatException('Μη έγκυρο .doc — κενός κατάλογος');
    }

    final miniStream = readStream(root.start, root.size);
    final miniFat = <int>[];
    if (numMiniFat > 0) {
      final mf = readStream(miniFatStart);
      final mv = ByteData.sublistView(mf);
      for (var k = 0; k + 4 <= mf.length; k += 4) {
        miniFat.add(mv.getUint32(k, Endian.little));
      }
    }

    return _Cfb._(miniSize, cutoff, fat, miniFat, miniStream,
        entries, readStream);
  }

  Uint8List? stream(String name) {
    final e = _entries[name];
    if (e == null) return null;
    if (e.size >= _cutoff) {
      return _readStream(e.start, e.size);
    }
    // Μικρό stream: ζει μέσα στο mini stream.
    final b = BytesBuilder();
    var s = e.start;
    var guard = 0;
    while (s < _maxRegular && guard <= _miniFat.length) {
      final off = s * _miniSize;
      if (off >= _miniStream.length) break;
      final end = off + _miniSize > _miniStream.length ? _miniStream.length : off + _miniSize;
      b.add(Uint8List.sublistView(_miniStream, off, end));
      if (s >= _miniFat.length) break;
      s = _miniFat[s];
      guard++;
    }
    final all = b.toBytes();
    return e.size >= all.length ? all : Uint8List.sublistView(all, 0, e.size);
  }
}

class _DirEntry {
  final String name;
  final int type;
  final int start;
  final int size;
  const _DirEntry(this.name, this.type, this.start, this.size);
}
