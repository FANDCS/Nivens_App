import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../core/storage/nivens_folder.dart';

/// Ανάγνωση αρχείων Word (.docx) χωρίς εξωτερικό πακέτο.
///
/// Ένα .docx είναι στην πραγματικότητα ένα ZIP (OOXML). Διαβάζουμε το
/// `word/document.xml`, το μετατρέπουμε σε **Markdown** (επικεφαλίδες,
/// έντονα/πλάγια, λίστες, πίνακες) και εξάγουμε τις ενσωματωμένες εικόνες
/// (`word/media/*`) στον φάκελο Nivens/images ώστε να εμφανίζονται και
/// αυτές μέσα στη σημείωση.
///
/// Σημείωση: το παλιό binary `.doc` (Word 97-2003) ΔΕΝ υποστηρίζεται —
/// ο χρήστης πρέπει να το σώσει ως .docx.
class DocxReader {
  DocxReader._();

  static Future<DocxContent> readFile(File file) async {
    final bytes = await file.readAsBytes();
    return readBytes(bytes, baseName: p.basenameWithoutExtension(file.path));
  }

  static Future<DocxContent> readBytes(Uint8List bytes, {String baseName = 'word'}) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? docXml;
    final media = <String, List<int>>{};
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (f.name == 'word/document.xml') docXml = f;
      if (f.name.startsWith('word/media/')) media[p.basename(f.name)] = f.content as List<int>;
    }
    if (docXml == null) {
      throw const FormatException('Μη έγκυρο .docx — λείπει το word/document.xml');
    }

    // Εξαγωγή εικόνων στον φάκελο Nivens/images
    final imagePaths = <String>[];
    if (media.isNotEmpty) {
      final dir = await NivensFolder.sub('images');
      final ts = DateTime.now().millisecondsSinceEpoch;
      var i = 0;
      for (final entry in media.entries) {
        final out = File(p.join(dir.path, '${baseName}_${ts}_${i++}${p.extension(entry.key)}'));
        await out.writeAsBytes(entry.value);
        imagePaths.add(out.path);
      }
    }

    final xml = utf8.decode(docXml.content as List<int>, allowMalformed: true);
    final markdown = _xmlToMarkdown(xml);

    return DocxContent(markdown: markdown, imagePaths: imagePaths);
  }

  // ── XML → Markdown ────────────────────────────────────────────────────────

  static final _paragraphRe = RegExp(r'<w:p[ >][\s\S]*?</w:p>|<w:p/>');
  static final _runRe = RegExp(r'<w:r[ >][\s\S]*?</w:r>');
  static final _textRe = RegExp(r'<w:t(?:\s[^>]*)?>([\s\S]*?)</w:t>');
  static final _styleRe = RegExp(r'<w:pStyle\s+w:val="([^"]+)"');
  static final _numPrRe = RegExp(r'<w:numPr[ >]');
  static final _tableRe = RegExp(r'<w:tbl>[\s\S]*?</w:tbl>');

  static String _xmlToMarkdown(String xml) {
    final buf = StringBuffer();

    // Κόβουμε το body σε μπλοκ (παράγραφοι + πίνακες) με τη σειρά που
    // εμφανίζονται στο έγγραφο.
    final blocks = <_Block>[];
    for (final m in _paragraphRe.allMatches(xml)) {
      blocks.add(_Block(m.start, _paragraphToMarkdown(m.group(0)!)));
    }
    for (final m in _tableRe.allMatches(xml)) {
      blocks.add(_Block(m.start, _tableToMarkdown(m.group(0)!)));
    }
    // Οι παράγραφοι μέσα στους πίνακες έχουν ήδη περιληφθεί στον πίνακα:
    // τις αφαιρούμε ώστε να μη διπλογραφούν.
    final tableRanges = _tableRe.allMatches(xml).map((m) => [m.start, m.end]).toList();
    blocks.removeWhere((b) => tableRanges.any((r) =>
        b.offset > r[0] && b.offset < r[1] && !b.text.contains('|')));

    blocks.sort((a, b) => a.offset.compareTo(b.offset));
    for (final b in blocks) {
      if (b.text.trim().isEmpty) {
        buf.writeln();
      } else {
        buf.writeln(b.text);
        buf.writeln();
      }
    }
    return buf.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _paragraphToMarkdown(String pXml) {
    final styleMatch = _styleRe.firstMatch(pXml);
    final style = styleMatch?.group(1)?.toLowerCase() ?? '';

    final sb = StringBuffer();
    for (final r in _runRe.allMatches(pXml)) {
      final runXml = r.group(0)!;
      final text = _textRe
          .allMatches(runXml)
          .map((m) => _unescape(m.group(1) ?? ''))
          .join();
      if (text.isEmpty) continue;
      final bold = runXml.contains('<w:b/>') || runXml.contains('<w:b ');
      final italic = runXml.contains('<w:i/>') || runXml.contains('<w:i ');
      final underline = runXml.contains('<w:u ');
      final strike = runXml.contains('<w:strike/>') || runXml.contains('<w:strike ');
      var t = text;
      if (bold) t = '**$t**';
      if (italic) t = '*$t*';
      if (underline) t = '<u>$t</u>';
      if (strike) t = '~~$t~~';
      sb.write(t);
    }
    var line = sb.toString().trim();
    if (line.isEmpty) return '';

    // Επικεφαλίδες (Heading1..Heading6 / Title)
    final headingMatch = RegExp(r'heading(\d)').firstMatch(style);
    if (headingMatch != null) {
      final level = int.parse(headingMatch.group(1)!).clamp(1, 6);
      return '${'#' * level} $line';
    }
    if (style == 'title') return '# $line';
    if (style.contains('quote')) return '> $line';

    // Λίστες
    if (_numPrRe.hasMatch(pXml)) {
      final ordered = style.contains('number') || pXml.contains('<w:numId w:val="2"');
      return ordered ? '1. $line' : '- $line';
    }
    return line;
  }

  static String _tableToMarkdown(String tblXml) {
    final rows = RegExp(r'<w:tr[ >][\s\S]*?</w:tr>').allMatches(tblXml).toList();
    if (rows.isEmpty) return '';
    final out = <String>[];
    for (var i = 0; i < rows.length; i++) {
      final cells = RegExp(r'<w:tc>[\s\S]*?</w:tc>')
          .allMatches(rows[i].group(0)!)
          .map((c) => _textRe
              .allMatches(c.group(0)!)
              .map((m) => _unescape(m.group(1) ?? ''))
              .join()
              .replaceAll('|', r'\|')
              .trim())
          .toList();
      if (cells.isEmpty) continue;
      out.add('| ${cells.join(' | ')} |');
      if (i == 0) out.add('|${List.filled(cells.length, ' --- ').join('|')}|');
    }
    return out.join('\n');
  }

  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

class _Block {
  final int offset;
  final String text;
  _Block(this.offset, this.text);
}

class DocxContent {
  /// Το κείμενο του εγγράφου σε markdown.
  final String markdown;

  /// Τοπικές διαδρομές των εικόνων που είχε μέσα το .docx.
  final List<String> imagePaths;

  const DocxContent({required this.markdown, required this.imagePaths});

  /// Markdown + τις εικόνες στο τέλος (ώστε να φαίνονται στην Προβολή).
  String get markdownWithImages {
    if (imagePaths.isEmpty) return markdown;
    final imgs = imagePaths.map((p) => '![εικόνα]($p "w=60")').join('\n\n');
    return '$markdown\n\n$imgs\n';
  }
}
