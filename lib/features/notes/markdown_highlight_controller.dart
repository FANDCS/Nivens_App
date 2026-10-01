import 'package:flutter/material.dart';

/// TextEditingController "drop-in" αντικαταστάτης του κανονικού, που
/// προσθέτει live syntax-styling πάνω στο ΙΔΙΟ, αναλλοίωτο raw markdown
/// κείμενο (δεν αλλάζει ό,τι είναι αποθηκευμένο/exported/synced — μόνο το
/// πώς αποδίδεται ΟΠΤΙΚΑ μέσα στο TextField).
///
/// Όταν [highlightEnabled] == true (δηλαδή η "Λειτουργία προγραμματιστή"
/// είναι ΑΝΕΝΕΡΓΗ): οι χαρακτήρες-δείκτες (`**`, `*`, `` ` ``, `~~`, `<u>`,
/// `#`) εμφανίζονται μικροί/αχνοί, ενώ το κείμενο ανάμεσά τους παίρνει την
/// πραγματική μορφοποίηση (έντονα/πλάγια/monospace/διαγραμμένα/υπογραμμισμ-
/// ένα/μεγαλύτερος τίτλος) — σαν κλασικό WYSIWYG, χωρίς όμως να αφαιρεί
/// τους χαρακτήρες από το κείμενο (παραμένουν πλήρως επεξεργάσιμοι/
/// διαγράψιμοι, το cursor περνάει κανονικά από πάνω τους).
///
/// Όταν [highlightEnabled] == false ("Λειτουργία προγραμματιστή" ΕΝΕΡΓΗ):
/// συμπεριφέρεται ΑΚΡΙΒΩΣ σαν κανονικό TextEditingController — καθαρό raw
/// markdown, καμία ειδική απόδοση.
class MarkdownHighlightController extends TextEditingController {
  bool highlightEnabled;

  MarkdownHighlightController({super.text, this.highlightEnabled = true});

  static final RegExp _headingPattern = RegExp(r'^(#{1,3}\s+)(.*)$');
  static final RegExp _inlinePattern = RegExp(
    r'(\*\*.+?\*\*)|(~~.+?~~)|(<u>.+?</u>)|(`[^`\n]+?`)|(\*[^\s*].*?\*)',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Ενεργό IME composing (π.χ. προβλεπτικό κείμενο) -> άφησέ το στο
    // προεπιλεγμένο rendering, μη μπλέξεις με το underline του συστήματος.
    if (!highlightEnabled || (withComposing && value.composing.isValid)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final base = style ?? const TextStyle();
    final markerStyle = base.copyWith(
      color: (base.color ?? Colors.black).withValues(alpha: 0.35),
      fontSize: (base.fontSize ?? 14) * 0.82,
    );

    final lines = text.split('\n');
    final spans = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      spans.addAll(_lineSpans(lines[i], base, markerStyle));
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return TextSpan(style: base, children: spans);
  }

  List<InlineSpan> _lineSpans(String line, TextStyle base, TextStyle markerStyle) {
    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      final marker = heading.group(1)!;
      final rest = heading.group(2)!;
      final level = marker.trim().length;
      final headingStyle = base.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: (base.fontSize ?? 14) * (level == 1 ? 1.5 : (level == 2 ? 1.32 : 1.18)),
      );
      return [
        TextSpan(text: marker, style: markerStyle),
        ..._inlineSpans(rest, headingStyle, markerStyle),
      ];
    }
    return _inlineSpans(line, base, markerStyle);
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle base, TextStyle markerStyle) {
    if (text.isEmpty) return const [TextSpan(text: '')];
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inlinePattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      final token = m.group(0)!;
      if (token.startsWith('**')) {
        _wrapped(spans, token, 2, 2, base.copyWith(fontWeight: FontWeight.bold), markerStyle);
      } else if (token.startsWith('~~')) {
        _wrapped(spans, token, 2, 2, base.copyWith(decoration: TextDecoration.lineThrough), markerStyle);
      } else if (token.startsWith('<u>')) {
        _wrapped(spans, token, 3, 4, base.copyWith(decoration: TextDecoration.underline), markerStyle);
      } else if (token.startsWith('`')) {
        _wrapped(spans, token, 1, 1, base.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['monospace']), markerStyle);
      } else {
        _wrapped(spans, token, 1, 1, base.copyWith(fontStyle: FontStyle.italic), markerStyle);
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
    return spans;
  }

  void _wrapped(
    List<InlineSpan> spans,
    String token,
    int openLen,
    int closeLen,
    TextStyle innerStyle,
    TextStyle markerStyle,
  ) {
    spans.add(TextSpan(text: token.substring(0, openLen), style: markerStyle));
    spans.add(TextSpan(text: token.substring(openLen, token.length - closeLen), style: innerStyle));
    spans.add(TextSpan(text: token.substring(token.length - closeLen), style: markerStyle));
  }
}
