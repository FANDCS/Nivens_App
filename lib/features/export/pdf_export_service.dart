import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_service.dart' show ExportViewMode;

/// Μετατρέπει μια σημείωση (τίτλος + markdown σώμα) σε PDF, για τις
/// επιλογές "Εξαγωγή ως PDF" και "Εκτύπωση" (η εκτύπωση φτιάχνει το ίδιο
/// PDF και το περνάει στο σύστημα εκτύπωσης/preview του λειτουργικού).
///
/// Δύο όψεις ([ExportViewMode]): `review` (προεπιλογή) = αποδοσμένο markdown
/// όπως στην Προβολή· `edit` = το κείμενο όπως φαίνεται στη λειτουργία
/// επεξεργασίας, δηλαδή το markdown ΜΕ τα σύμβολά του (#, **, `...`), με
/// την ίδια ελαφριά μορφοποίηση που έχει ο editor όταν η «Λειτουργία
/// προγραμματιστή» είναι ανενεργή ([buildNotePdf.editHighlight]).
///
/// Χρησιμοποιεί τα δικά της γραμματοσειρές (NotoSansPdf/NotoSansMonoPdf,
/// δες pubspec.yaml) αντί για κάποιο google_font της εφαρμογής, ώστε να
/// δουλεύει πάντα ελληνικό κείμενο χωρίς σύνδεση στο internet.
///
/// Υποστηρίζει ένα ΠΡΑΚΤΙΚΟ υποσύνολο του markdown της εφαρμογής:
/// επικεφαλίδες (#/##/###), **bold**, *italic*, `inline code`, code blocks
/// (```), λίστες (- / 1.), task list ([ ]/[x]), blockquote (>) και απλούς
/// πίνακες (| a | b |). Αν δοθεί [buildNotePdf.overlayBytes] (η ζωγραφιά
/// "πάνω από όλα" της σημείωσης), μπαίνει σε ΔΙΚΗ ΤΗΣ σελίδα στο τέλος —
/// δεν στοιχίζεται pixel-perfect πάνω στο κείμενο, αλλά πλέον ΦΑΙΝΕΤΑΙ.
/// Ενσωματωμένες εικόνες μέσα στο markdown (`![...](file://...)`) δεν
/// αποδίδονται ακόμα.
class PdfExportService {
  PdfExportService._();

  static pw.Font? _regular, _bold, _italic, _boldItalic, _mono;

  static Future<void> _ensureFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    _italic ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Italic.ttf'));
    _boldItalic ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-BoldItalic.ttf'));
    _mono ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansMono-Regular.ttf'));
  }

  static Future<Uint8List> buildNotePdf({
    required String title,
    required String body,
    double fontSize = 11,
    Uint8List? overlayBytes,
    ExportViewMode mode = ExportViewMode.review,
    bool editHighlight = true,
  }) async {
    await _ensureFonts();
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      italic: _italic!,
      boldItalic: _boldItalic!,
    );
    final blocks = mode == ExportViewMode.edit
        ? _RawMarkdownToPdf(fontSize: fontSize, mono: _mono!, highlight: editHighlight).parse(body)
        : _MarkdownToPdf(fontSize: fontSize, mono: _mono!).parse(body);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        maxPages: 2000,
        margin: const pw.EdgeInsets.fromLTRB(40, 48, 40, 40),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${ctx.pageNumber}/${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          pw.Text(
            title.trim().isEmpty ? '(χωρίς τίτλο)' : title.trim(),
            style: pw.TextStyle(fontSize: fontSize * 1.9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          ...blocks,
        ],
      ),
    );

    // Η ζωγραφιά (overlay layer πάνω από όλη τη σημείωση, βλ.
    // note_editor_screen._drawOverEverything) δεν είναι μέρος του markdown
    // -- δεν υπάρχει αξιόπιστος τρόπος να "στοιχηθεί" pixel-perfect πάνω
    // στο ήδη paginated κείμενο (διαφορετική μηχανή rendering). Μπαίνει σε
    // δική της σελίδα στο τέλος, ώστε να ΦΑΙΝΕΤΑΙ στο εξαγόμενο/τυπωμένο
    // PDF αντί να λείπει εντελώς.
    // Στη λειτουργία επεξεργασίας η ζωγραφιά δεν φαίνεται (είναι layer της
    // Προβολής), άρα δεν μπαίνει ούτε στο PDF της όψης «edit».
    if (mode == ExportViewMode.review && overlayBytes != null && overlayBytes.isNotEmpty) {
      final overlayImage = pw.MemoryImage(overlayBytes);
      doc.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 32, 24, 32),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                tr('Σχέδιο (πάνω από τη σημείωση)', 'Drawing (over the note)'),
                style: pw.TextStyle(fontSize: fontSize * 1.2, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Expanded(child: pw.Center(child: pw.Image(overlayImage, fit: pw.BoxFit.contain))),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  /// Μικρό, τοπικό el/en helper — αυτό το αρχείο δεν έχει BuildContext
  /// (τρέχει σε background isolate-friendly κώδικα), οπότε δεν μπορεί να
  /// χρησιμοποιήσει το core/i18n.dart `tr(context, ...)`. Χρησιμοποιεί την
  /// τρέχουσα system locale του Flutter engine.
  static String tr(String el, String en) {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'el' ? el : en;
  }
}

/// Ελαφρύς, best-effort μετατροπέας markdown -> pdf widgets (γραμμή προς
/// γραμμή — δεν φτιάχνει πλήρες AST σαν το πακέτο `markdown`, αλλά καλύπτει
/// ό,τι πραγματικά παράγει ο editor της εφαρμογής).
class _MarkdownToPdf {
  final double fontSize;
  final pw.Font mono;
  _MarkdownToPdf({required this.fontSize, required this.mono});

  static final _heading = RegExp(r'^(#{1,3})\s+(.*)');
  static final _task = RegExp(r'^[-*+]\s+\[( |x|X)\]\s+(.*)');
  static final _unordered = RegExp(r'^[-*+]\s+(.*)');
  static final _ordered = RegExp(r'^(\d+)[.)]\s+(.*)');
  static final _inlinePattern = RegExp(r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)');

  List<pw.Widget> parse(String text) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final widgets = <pw.Widget>[];
    final tableRows = <List<String>>[];
    final codeBuffer = StringBuffer();
    var inCode = false;

    void flushTable() {
      if (tableRows.isEmpty) return;
      final header = tableRows.first;
      // Η 2η γραμμή ενός markdown πίνακα είναι πάντα ο διαχωριστής (---).
      final body = tableRows.length > 2 ? tableRows.sublist(2) : const <List<String>>[];
      widgets.add(pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              for (final c in header)
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _inline(c, bold: true)),
            ],
          ),
          for (final row in body)
            pw.TableRow(children: [
              for (final c in row) pw.Padding(padding: const pw.EdgeInsets.all(4), child: _inline(c)),
            ]),
        ],
      ));
      widgets.add(pw.SizedBox(height: 10));
      tableRows.clear();
    }

    void flushCode() {
      final code = codeBuffer.toString();
      if (code.trim().isNotEmpty) {
        widgets.add(pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(code.trimRight(), style: pw.TextStyle(font: mono, fontSize: fontSize * 0.85)),
        ));
      }
      codeBuffer.clear();
    }

    for (final raw in lines) {
      final trimmed = raw.trimLeft();

      if (trimmed.startsWith('```')) {
        if (inCode) {
          flushCode();
          inCode = false;
        } else {
          flushTable();
          inCode = true;
        }
        continue;
      }
      if (inCode) {
        codeBuffer.writeln(raw);
        continue;
      }

      final isTableRow = trimmed.startsWith('|') && trimmed.trimRight().endsWith('|');
      if (isTableRow) {
        final inner = trimmed.trim();
        tableRows.add(inner.substring(1, inner.length - 1).split('|').map((s) => s.trim()).toList());
        continue;
      } else if (tableRows.isNotEmpty) {
        flushTable();
      }

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      final h = _heading.firstMatch(trimmed);
      if (h != null) {
        final level = h.group(1)!.length;
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(top: level == 1 ? 2 : 10, bottom: 6),
          child: _inline(
            h.group(2)!,
            bold: true,
            sizeMultiplier: level == 1 ? 1.5 : (level == 2 ? 1.3 : 1.15),
          ),
        ));
        continue;
      }

      if (trimmed.startsWith('>')) {
        widgets.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.only(left: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColors.grey500, width: 2)),
          ),
          child: _inline(trimmed.replaceFirst(RegExp(r'^>\s?'), ''), italic: true),
        ));
        continue;
      }

      final task = _task.firstMatch(trimmed);
      if (task != null) {
        final checked = task.group(1)!.toLowerCase() == 'x';
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(checked ? '\u2611 ' : '\u2610 ', style: pw.TextStyle(fontSize: fontSize)),
            pw.Expanded(child: _inline(task.group(2)!)),
          ]),
        ));
        continue;
      }

      final ul = _unordered.firstMatch(trimmed);
      if (ul != null) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('\u2022  ', style: pw.TextStyle(fontSize: fontSize)),
            pw.Expanded(child: _inline(ul.group(1)!)),
          ]),
        ));
        continue;
      }

      final ol = _ordered.firstMatch(trimmed);
      if (ol != null) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${ol.group(1)}.  ', style: pw.TextStyle(fontSize: fontSize)),
            pw.Expanded(child: _inline(ol.group(2)!)),
          ]),
        ));
        continue;
      }

      widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: _inline(trimmed)));
    }
    if (inCode) flushCode();
    flushTable();
    return widgets;
  }

  pw.Widget _inline(String text, {bool bold = false, bool italic = false, double sizeMultiplier = 1}) {
    final spans = <pw.InlineSpan>[];
    var last = 0;
    for (final m in _inlinePattern.allMatches(text)) {
      if (m.start > last) spans.add(pw.TextSpan(text: text.substring(last, m.start)));
      if (m.group(2) != null) {
        spans.add(pw.TextSpan(text: m.group(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      } else if (m.group(4) != null) {
        spans.add(pw.TextSpan(text: m.group(4), style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
      } else if (m.group(6) != null) {
        spans.add(pw.TextSpan(
          text: m.group(6),
          style: pw.TextStyle(font: mono, fontSize: fontSize * sizeMultiplier * 0.9),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(pw.TextSpan(text: text.substring(last)));
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: fontSize * sizeMultiplier,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        ),
        children: spans,
      ),
    );
  }
}

/// Όψη «edit» του PDF: το κείμενο της σημείωσης ΩΣ ΕΧΕΙ (raw markdown, μία
/// γραμμή ανά γραμμή του editor, με διατήρηση κενών γραμμών/εσοχών), όχι
/// αποδοσμένο. Με [highlight] = true μιμείται το MarkdownHighlightController
/// του editor: οι χαρακτήρες-δείκτες (`**`, `*`, `` ` ``, `~~`, `<u>`, `#`)
/// βγαίνουν μικροί/αχνοί και το κείμενο ανάμεσά τους παίρνει μορφοποίηση
/// (έντονα/πλάγια/monospace/διαγραμμένα/υπογραμμισμένα/μεγαλύτερος τίτλος).
/// Με [highlight] = false (Λειτουργία προγραμματιστή) βγαίνει καθαρό κείμενο.
class _RawMarkdownToPdf {
  final double fontSize;
  final pw.Font mono;
  final bool highlight;
  _RawMarkdownToPdf({required this.fontSize, required this.mono, required this.highlight});

  // Ίδια regex με το lib/features/notes/markdown_highlight_controller.dart,
  // ώστε το PDF να δείχνει ό,τι δείχνει και ο editor.
  static final _headingPattern = RegExp(r'^(#{1,3}\s+)(.*)$');
  static final _inlinePattern = RegExp(
    r'(\*\*.+?\*\*)|(~~.+?~~)|(<u>.+?</u>)|(`[^`\n]+?`)|(\*[^\s*].*?\*)',
  );

  static const _markerColor = PdfColors.grey500;
  static const _lineGap = 3.0;

  List<pw.Widget> parse(String text) {
    final lines = text.replaceAll('\r\n', '\n').replaceAll('\t', '    ').split('\n');
    final widgets = <pw.Widget>[];
    for (final line in lines) {
      if (line.isEmpty) {
        widgets.add(pw.SizedBox(height: fontSize + _lineGap));
        continue;
      }
      widgets.add(pw.RichText(text: _lineSpan(line)));
    }
    return widgets;
  }

  pw.TextStyle get _base => pw.TextStyle(fontSize: fontSize, lineSpacing: _lineGap);

  pw.TextSpan _lineSpan(String line) {
    if (!highlight) return pw.TextSpan(text: line, style: _base);

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      final marker = heading.group(1)!;
      final level = marker.trim().length;
      final headingStyle = _base.copyWith(
        fontWeight: pw.FontWeight.bold,
        fontSize: fontSize * (level == 1 ? 1.5 : (level == 2 ? 1.32 : 1.18)),
      );
      return pw.TextSpan(
        style: _base,
        children: [
          pw.TextSpan(text: marker, style: _markerStyle(headingStyle)),
          ..._inlineSpans(heading.group(2)!, headingStyle),
        ],
      );
    }
    return pw.TextSpan(style: _base, children: _inlineSpans(line, _base));
  }

  pw.TextStyle _markerStyle(pw.TextStyle base) => base.copyWith(
        color: _markerColor,
        fontSize: (base.fontSize ?? fontSize) * 0.82,
        fontWeight: pw.FontWeight.normal,
      );

  List<pw.InlineSpan> _inlineSpans(String text, pw.TextStyle base) {
    if (text.isEmpty) return const [];
    final spans = <pw.InlineSpan>[];
    var last = 0;
    for (final m in _inlinePattern.allMatches(text)) {
      if (m.start > last) spans.add(pw.TextSpan(text: text.substring(last, m.start), style: base));
      final token = m.group(0)!;
      if (token.startsWith('**')) {
        _wrapped(spans, token, 2, 2, base.copyWith(fontWeight: pw.FontWeight.bold), base);
      } else if (token.startsWith('~~')) {
        _wrapped(spans, token, 2, 2, base.copyWith(decoration: pw.TextDecoration.lineThrough), base);
      } else if (token.startsWith('<u>')) {
        _wrapped(spans, token, 3, 4, base.copyWith(decoration: pw.TextDecoration.underline), base);
      } else if (token.startsWith('`')) {
        _wrapped(spans, token, 1, 1, base.copyWith(font: mono), base);
      } else {
        _wrapped(spans, token, 1, 1, base.copyWith(fontStyle: pw.FontStyle.italic), base);
      }
      last = m.end;
    }
    if (last < text.length) spans.add(pw.TextSpan(text: text.substring(last), style: base));
    return spans;
  }

  void _wrapped(
    List<pw.InlineSpan> spans,
    String token,
    int openLen,
    int closeLen,
    pw.TextStyle innerStyle,
    pw.TextStyle base,
  ) {
    spans.add(pw.TextSpan(text: token.substring(0, openLen), style: _markerStyle(base)));
    spans.add(pw.TextSpan(text: token.substring(openLen, token.length - closeLen), style: innerStyle));
    spans.add(pw.TextSpan(text: token.substring(token.length - closeLen), style: _markerStyle(base)));
  }
}
