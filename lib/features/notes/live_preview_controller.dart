import 'package:flutter/material.dart';
import 'code_highlighter.dart';
import 'markdown_highlight_controller.dart';

/// Controller του editor με δύο όψεις:
///  * [renderedMode] == false  → η υπάρχουσα ελαφριά μορφοποίηση του
///    [MarkdownHighlightController] (σύμβολα markdown ορατά, με χρώμα/στυλ).
///    Αυτό ισχύει όταν η «Λειτουργία προγραμματιστή» είναι ΕΝΕΡΓΗ.
///  * [renderedMode] == true   → ο editor δείχνει το κείμενο «σαν Προβολή»:
///    επικεφαλίδες μεγάλες, έντονα/πλάγια/διαγραμμένα κ.λπ. και τα σύμβολα
///    (#, **, _, ~~, `, [](…)) κρύβονται. Στη γραμμή όπου βρίσκεται ο
///    κέρσορας τα σύμβολα εμφανίζονται αχνά, ώστε να μπορείς να τα
///    επεξεργαστείς. Ισχύει όταν η «Λειτουργία προγραμματιστή» είναι ΑΝΕΝΕΡΓΗ.
///
/// Σημαντικό: το TextSpan που επιστρέφεται έχει ΠΑΝΤΑ ακριβώς το ίδιο
/// μήκος κειμένου με το [text] (τα σύμβολα κρύβονται με στυλ, δεν
/// αφαιρούνται), ώστε ο κέρσορας/η επιλογή να μένουν σωστά.
class LivePreviewController extends MarkdownHighlightController {
  DocType _docType = DocType.markdown;
  DocType get docType => _docType;
  set docType(DocType v) {
    if (_docType == v) return;
    _docType = v;
    notifyListeners();
  }

  bool _renderedMode = false;
  bool get renderedMode => _renderedMode;
  set renderedMode(bool v) {
    if (_renderedMode == v) return;
    _renderedMode = v;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Έγγραφο κώδικα (Python, Java, …): χρωματισμός εντολών, ανεξάρτητα από
    // τη Λειτουργία προγραμματιστή.
    if (_docType.isCode) {
      final base = (style ?? DefaultTextStyle.of(context).style)
          .copyWith(fontFamily: 'monospace');
      return TextSpan(
        style: base,
        children: CodeHighlighter.highlight(
            text, _docType, base, Theme.of(context).brightness),
      );
    }
    if (!_renderedMode) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }
    final base = style ?? DefaultTextStyle.of(context).style;
    final scheme = Theme.of(context).colorScheme;
    final sel = selection;
    final caret = sel.isValid ? sel.extentOffset : -1;

    final children = <InlineSpan>[];
    final src = text;
    var lineStart = 0;
    var inFence = false;

    while (lineStart <= src.length) {
      var lineEnd = src.indexOf('\n', lineStart);
      final hasNewline = lineEnd != -1;
      if (!hasNewline) lineEnd = src.length;
      final line = src.substring(lineStart, lineEnd);
      final isCaretLine = caret >= lineStart &&
          (caret <= lineEnd) &&
          sel.isValid &&
          _selectionTouches(sel, lineStart, lineEnd);

      children.addAll(_renderLine(
        line,
        base,
        scheme,
        showMarkers: isCaretLine,
        inFence: inFence,
        onFenceToggle: () => inFence = !inFence,
      ));
      if (hasNewline) children.add(TextSpan(text: '\n', style: base));
      if (!hasNewline) break;
      lineStart = lineEnd + 1;
    }
    return TextSpan(style: base, children: children);
  }

  bool _selectionTouches(TextSelection sel, int start, int end) {
    final a = sel.start, b = sel.end;
    return a <= end && b >= start;
  }

  // ── Στυλ ────────────────────────────────────────────────────────────────

  TextStyle _hidden(TextStyle base) =>
      base.copyWith(color: Colors.transparent, fontSize: 0.1, height: 0.01);

  TextStyle _dim(TextStyle base, ColorScheme s) =>
      base.copyWith(color: s.onSurface.withOpacity(0.35));

  TextSpan _marker(String t, TextStyle base, ColorScheme s, bool show) =>
      TextSpan(text: t, style: show ? _dim(base, s) : _hidden(base));

  // ── Γραμμή ──────────────────────────────────────────────────────────────

  List<InlineSpan> _renderLine(
    String line,
    TextStyle base,
    ColorScheme s, {
    required bool showMarkers,
    required bool inFence,
    required VoidCallback onFenceToggle,
  }) {
    if (line.isEmpty) return const [];
    final size = base.fontSize ?? 16;
    final mono = base.copyWith(
      fontFamily: 'monospace',
      backgroundColor: s.surfaceContainerHighest,
    );

    // Φράχτης κώδικα ``` — η γραμμή του φράχτη κρύβεται (εκτός από τη
    // γραμμή του κέρσορα), το εσωτερικό δείχνεται ως monospace.
    if (line.trimLeft().startsWith('```')) {
      onFenceToggle();
      return [TextSpan(text: line, style: showMarkers ? _dim(mono, s) : _hidden(base))];
    }
    if (inFence) return [TextSpan(text: line, style: mono)];

    // Επικεφαλίδες
    final h = RegExp(r'^(#{1,6})(\s+)(.*)$').firstMatch(line);
    if (h != null) {
      final level = h.group(1)!.length;
      const scale = [1.6, 1.3, 1.15, 1.05, 1.0, 0.95];
      final hs = base.copyWith(
          fontSize: size * scale[level - 1], fontWeight: FontWeight.bold);
      return [
        _marker('${h.group(1)}${h.group(2)}', hs, s, showMarkers),
        ..._inline(h.group(3)!, hs, s, showMarkers),
      ];
    }

    // Οριζόντια γραμμή
    if (RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$').hasMatch(line)) {
      return [TextSpan(text: line, style: _dim(base, s))];
    }

    // Quote
    final q = RegExp(r'^(\s*>\s?)(.*)$').firstMatch(line);
    if (q != null) {
      final qs = base.copyWith(
          fontStyle: FontStyle.italic, color: s.onSurface.withOpacity(0.75));
      return [
        TextSpan(
            text: q.group(1),
            style: showMarkers
                ? _dim(base, s)
                : base.copyWith(color: s.primary, fontWeight: FontWeight.bold)),
        ..._inline(q.group(2)!, qs, s, showMarkers),
      ];
    }

    // Checkbox λίστα (- [ ] / - [x])
    final cb = RegExp(r'^(\s*[-*+]\s+)(\[[ xX]\])(\s?)(.*)$').firstMatch(line);
    if (cb != null) {
      final checked = cb.group(2)!.toLowerCase() == '[x]';
      final rest = checked
          ? base.copyWith(
              decoration: TextDecoration.lineThrough,
              color: s.onSurface.withOpacity(0.55))
          : base;
      return [
        TextSpan(text: cb.group(1), style: showMarkers ? _dim(base, s) : base.copyWith(color: s.primary)),
        TextSpan(
            text: cb.group(2),
            style: base.copyWith(
                color: checked ? s.primary : s.onSurfaceVariant,
                fontWeight: FontWeight.bold)),
        TextSpan(text: cb.group(3), style: base),
        ..._inline(cb.group(4)!, rest, s, showMarkers),
      ];
    }

    // Λίστα (- , * , + , 1. )
    final li = RegExp(r'^(\s*(?:[-*+]|\d+[.)])\s+)(.*)$').firstMatch(line);
    if (li != null) {
      return [
        TextSpan(
            text: li.group(1),
            style: base.copyWith(color: s.primary, fontWeight: FontWeight.bold)),
        ..._inline(li.group(2)!, base, s, showMarkers),
      ];
    }

    return _inline(line, base, s, showMarkers);
  }

  // ── Inline (έντονα, πλάγια, κ.λπ.) ──────────────────────────────────────

  static final RegExp _inlineRe = RegExp(
    r'(?<code>`[^`\n]+`)'
    r'|(?<image>!\[[^\]\n]*\]\([^)\n]*\))'
    r'|(?<link>\[[^\]\n]+\]\([^)\n]*\))'
    r'|(?<bold>\*\*(?=\S)(?:.+?)(?<=\S)\*\*|__(?=\S)(?:.+?)(?<=\S)__)'
    r'|(?<strike>~~(?=\S)(?:.+?)(?<=\S)~~)'
    r'|(?<italic>\*(?=[^\s*])(?:[^*\n]+?)(?<=[^\s*])\*|(?<![A-Za-z0-9_])_(?=[^\s_])(?:[^_\n]+?)(?<=[^\s_])_(?![A-Za-z0-9_]))',
  );

  List<InlineSpan> _inline(
      String s0, TextStyle base, ColorScheme s, bool show) {
    final out = <InlineSpan>[];
    var pos = 0;
    for (final m in _inlineRe.allMatches(s0)) {
      if (m.start > pos) {
        out.add(TextSpan(text: s0.substring(pos, m.start), style: base));
      }
      final t = m.group(0)!;
      if (m.namedGroup('code') != null) {
        out.add(_marker('`', base, s, show));
        out.add(TextSpan(
            text: t.substring(1, t.length - 1),
            style: base.copyWith(
                fontFamily: 'monospace',
                backgroundColor: s.surfaceContainerHighest)));
        out.add(_marker('`', base, s, show));
      } else if (m.namedGroup('image') != null) {
        out.add(TextSpan(text: t, style: _dim(base, s)));
      } else if (m.namedGroup('link') != null) {
        final close = t.indexOf('](');
        out.add(_marker('[', base, s, show));
        out.add(TextSpan(
            text: t.substring(1, close),
            style: base.copyWith(
                color: s.primary, decoration: TextDecoration.underline)));
        out.add(_marker(t.substring(close), base, s, show));
      } else if (m.namedGroup('bold') != null) {
        out.add(_marker(t.substring(0, 2), base, s, show));
        out.addAll(_inline(t.substring(2, t.length - 2),
            base.copyWith(fontWeight: FontWeight.bold), s, show));
        out.add(_marker(t.substring(t.length - 2), base, s, show));
      } else if (m.namedGroup('strike') != null) {
        out.add(_marker('~~', base, s, show));
        out.addAll(_inline(t.substring(2, t.length - 2),
            base.copyWith(decoration: TextDecoration.lineThrough), s, show));
        out.add(_marker('~~', base, s, show));
      } else {
        out.add(_marker(t.substring(0, 1), base, s, show));
        out.addAll(_inline(t.substring(1, t.length - 1),
            base.copyWith(fontStyle: FontStyle.italic), s, show));
        out.add(_marker(t.substring(t.length - 1), base, s, show));
      }
      pos = m.end;
    }
    if (pos < s0.length) {
      out.add(TextSpan(text: s0.substring(pos), style: base));
    }
    return out;
  }
}
