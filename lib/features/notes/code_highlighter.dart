import 'package:flutter/material.dart';

/// Τύπος εγγράφου μιας σημείωσης. Το [markdown] (Κείμενο/MD) είναι το
/// προεπιλεγμένο όταν δεν έχει επιλεγεί κάτι.
enum DocType {
  markdown('markdown', 'Κείμενο / Markdown', 'Text / Markdown', Icons.notes),
  python('python', 'Python', 'Python', Icons.terminal),
  java('java', 'Java', 'Java', Icons.coffee_outlined),
  flutter('flutter', 'Flutter (Dart)', 'Flutter (Dart)', Icons.flutter_dash),
  html('html', 'HTML', 'HTML', Icons.html),
  css('css', 'CSS', 'CSS', Icons.css),
  javascript('javascript', 'JavaScript', 'JavaScript', Icons.javascript),
  php('php', 'PHP', 'PHP', Icons.php);

  final String id;
  final String labelEl;
  final String labelEn;
  final IconData icon;
  const DocType(this.id, this.labelEl, this.labelEn, this.icon);

  bool get isCode => this != DocType.markdown;

  /// Ο τύπος αποθηκεύεται μέσα στη σημείωση ως δεσμευμένο tag (χωρίς αλλαγή
  /// σχήματος βάσης): `__type:python`. Το markdown δεν αποθηκεύεται (default).
  static const String tagPrefix = '__type:';
  String get tag => '$tagPrefix$id';

  static bool isTypeTag(String t) => t.startsWith(tagPrefix);

  static DocType fromTags(Iterable<String> tags) {
    for (final t in tags) {
      if (isTypeTag(t)) {
        final id = t.substring(tagPrefix.length);
        for (final d in DocType.values) {
          if (d.id == id) return d;
        }
      }
    }
    return DocType.markdown;
  }

  /// Αυτόματη επιλογή από την κατάληξη αρχείου (για εισαγόμενα αρχεία).
  static DocType fromFileName(String? path) {
    if (path == null) return DocType.markdown;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return DocType.markdown;
    switch (path.substring(dot + 1).toLowerCase()) {
      case 'py': return DocType.python;
      case 'java': return DocType.java;
      case 'dart': return DocType.flutter;
      case 'html':
      case 'htm': return DocType.html;
      case 'css': return DocType.css;
      case 'js':
      case 'mjs': return DocType.javascript;
      case 'php': return DocType.php;
      default: return DocType.markdown;
    }
  }
}

class _Palette {
  final Color keyword, string, comment, number, type, function, builtin,
      variable, tag, attribute, plain;
  const _Palette({
    required this.keyword, required this.string, required this.comment,
    required this.number, required this.type, required this.function,
    required this.builtin, required this.variable, required this.tag,
    required this.attribute, required this.plain,
  });

  static const dark = _Palette(
    keyword: Color(0xFFC586C0), string: Color(0xFFCE9178),
    comment: Color(0xFF6A9955), number: Color(0xFFB5CEA8),
    type: Color(0xFF4EC9B0), function: Color(0xFFDCDCAA),
    builtin: Color(0xFF569CD6), variable: Color(0xFF9CDCFE),
    tag: Color(0xFF569CD6), attribute: Color(0xFF9CDCFE),
    plain: Color(0xFFD4D4D4),
  );
  static const light = _Palette(
    keyword: Color(0xFFAF00DB), string: Color(0xFFA31515),
    comment: Color(0xFF008000), number: Color(0xFF098658),
    type: Color(0xFF267F99), function: Color(0xFF795E26),
    builtin: Color(0xFF0000FF), variable: Color(0xFF001080),
    tag: Color(0xFF800000), attribute: Color(0xFFE50000),
    plain: Color(0xFF1E1E1E),
  );
}

/// Χρωματισμός εντολών (syntax highlighting) βασισμένος σε regex.
/// Επιστρέφει spans που καλύπτουν ΑΚΡΙΒΩΣ το κείμενο (ίδιο μήκος), ώστε να
/// χρησιμοποιείται με ασφάλεια μέσα σε TextField controller.
class CodeHighlighter {
  static String _kw(List<String> w) => r'\b(?:' + w.join('|') + r')\b';

  static const _numRe = r'\b(?:0[xX][0-9a-fA-F_]+|\d[\d_]*\.?\d*(?:[eE][+-]?\d+)?)\b';
  static const _slashComments = r'//[^\n]*|/\*[\s\S]*?(?:\*/|$)';
  static const _dq = r'"(?:\\.|[^"\\\n])*"?';
  static const _sq = r"'(?:\\.|[^'\\\n])*'?";
  static const _func = r'\b[A-Za-z_$][\w$]*(?=\s*\()';
  static const _typeRe = r'\b[A-Z][A-Za-z0-9_]*\b';

  // Κάθε γλώσσα: λίστα (ομάδα, pattern) — προτεραιότητα με τη σειρά.
  static final Map<DocType, List<(String, String)>> _rules = {
    DocType.python: [
      ('comment', r'#[^\n]*'),
      ('string', r'''[rRbBfFuU]{0,2}(?:"""[\s\S]*?(?:"""|$)|\'\'\'[\s\S]*?(?:\'\'\'|$))'''),
      ('string', r'[rRbBfFuU]{0,2}(?:' + _dq + '|' + _sq + ')'),
      ('keyword', _kw(['False','None','True','and','as','assert','async','await','break','class','continue','def','del','elif','else','except','finally','for','from','global','if','import','in','is','lambda','nonlocal','not','or','pass','raise','return','try','while','with','yield','match','case'])),
      ('builtin', _kw(['print','len','range','int','str','float','list','dict','set','tuple','bool','input','open','type','isinstance','enumerate','zip','map','filter','sorted','sum','min','max','abs','self','cls','super'])),
      ('variable', r'@[A-Za-z_][\w.]*'),
      ('function', _func),
      ('type', _typeRe),
      ('number', _numRe),
    ],
    DocType.java: [
      ('comment', _slashComments),
      ('string', r'"""[\s\S]*?(?:"""|$)'),
      ('string', _dq + '|' + _sq),
      ('keyword', _kw(['abstract','assert','boolean','break','byte','case','catch','char','class','const','continue','default','do','double','else','enum','extends','final','finally','float','for','goto','if','implements','import','instanceof','int','interface','long','native','new','package','private','protected','public','return','short','static','strictfp','super','switch','synchronized','this','throw','throws','transient','try','var','void','volatile','while','record','sealed','permits','yield'])),
      ('builtin', _kw(['true','false','null'])),
      ('variable', r'@[A-Za-z_]\w*'),
      ('function', _func),
      ('type', _typeRe),
      ('number', _numRe + r'[lLfFdD]?'),
    ],
    DocType.flutter: [
      ('comment', _slashComments),
      ('string', r'''[rR]?(?:"""[\s\S]*?(?:"""|$)|\'\'\'[\s\S]*?(?:\'\'\'|$))'''),
      ('string', r'[rR]?(?:' + _dq + '|' + _sq + ')'),
      ('keyword', _kw(['abstract','as','assert','async','await','break','case','catch','class','const','continue','covariant','default','deferred','do','dynamic','else','enum','export','extends','extension','external','factory','final','finally','for','Function','get','hide','if','implements','import','in','interface','is','late','library','mixin','new','on','operator','part','required','rethrow','return','sealed','set','show','static','super','switch','sync','this','throw','try','typedef','var','void','while','with','yield'])),
      ('builtin', _kw(['true','false','null','int','double','num','bool','String','List','Map','Set','Future','Stream','void'])),
      ('variable', r'@[A-Za-z_]\w*'),
      ('function', _func),
      ('type', _typeRe),
      ('number', _numRe),
    ],
    DocType.javascript: [
      ('comment', _slashComments),
      ('string', r'`(?:\\[\s\S]|[^`\\])*`?'),
      ('string', _dq + '|' + _sq),
      ('keyword', _kw(['async','await','break','case','catch','class','const','continue','debugger','default','delete','do','else','export','extends','finally','for','from','function','if','import','in','instanceof','let','new','of','return','static','super','switch','this','throw','try','typeof','var','void','while','with','yield'])),
      ('builtin', _kw(['true','false','null','undefined','NaN','Infinity','console','document','window','Math','JSON','Promise','Array','Object'])),
      ('function', _func),
      ('type', _typeRe),
      ('number', _numRe),
    ],
    DocType.php: [
      ('tag', r'<\?php|<\?=|\?>'),
      ('comment', _slashComments + r'|#[^\n]*'),
      ('string', _dq + '|' + _sq),
      ('variable', r'\$[A-Za-z_]\w*'),
      ('keyword', _kw(['abstract','and','array','as','break','callable','case','catch','class','clone','const','continue','declare','default','do','echo','else','elseif','empty','enddeclare','endfor','endforeach','endif','endswitch','endwhile','extends','final','finally','fn','for','foreach','function','global','if','implements','include','include_once','instanceof','interface','isset','list','match','namespace','new','or','print','private','protected','public','readonly','require','require_once','return','static','switch','throw','trait','try','unset','use','var','while','xor','yield'])),
      ('builtin', _kw(['true','false','null','TRUE','FALSE','NULL'])),
      ('function', _func),
      ('type', _typeRe),
      ('number', _numRe),
    ],
    DocType.css: [
      ('comment', r'/\*[\s\S]*?(?:\*/|$)'),
      ('string', _dq + '|' + _sq),
      ('keyword', r'@[A-Za-z-]+'),
      ('number', r'#[0-9a-fA-F]{3,8}\b'),
      ('number', r'-?\d*\.?\d+(?:px|em|rem|vh|vw|vmin|vmax|%|s|ms|deg|fr|ch|pt|cm|mm)?\b'),
      ('attribute', r'[A-Za-z-]+(?=\s*:(?!:))'),
      ('type', r'[.#][A-Za-z_][\w-]*'),
      ('builtin', r'!important'),
      ('function', r'[A-Za-z-]+(?=\()'),
      ('tag', r'::?[A-Za-z-]+'),
    ],
    DocType.html: [
      ('comment', r'<!--[\s\S]*?(?:-->|$)'),
      ('keyword', r'<![A-Za-z][^>]*>?'),
      ('tag', r'</?[A-Za-z][\w:-]*'),
      ('tag', r'/?>'),
      ('string', _dq + '|' + _sq),
      ('attribute', r'[A-Za-z_:@][\w:.-]*(?=\s*=)'),
      ('builtin', r'&[A-Za-z#0-9]+;'),
    ],
  };

  static final Map<DocType, RegExp> _compiled = {};

  static RegExp _regexFor(DocType t) {
    return _compiled.putIfAbsent(t, () {
      final rules = _rules[t]!;
      final parts = <String>[];
      for (var i = 0; i < rules.length; i++) {
        parts.add('(?<g$i>${rules[i].$2})');
      }
      return RegExp(parts.join('|'), multiLine: false);
    });
  }

  static List<InlineSpan> highlight(
      String text, DocType type, TextStyle base, Brightness brightness) {
    if (!type.isCode || text.isEmpty) {
      return [TextSpan(text: text, style: base)];
    }
    final pal = brightness == Brightness.dark ? _Palette.dark : _Palette.light;
    final rules = _rules[type]!;
    final re = _regexFor(type);
    final out = <InlineSpan>[];
    var pos = 0;

    Color colorFor(String group) {
      switch (group) {
        case 'keyword': return pal.keyword;
        case 'string': return pal.string;
        case 'comment': return pal.comment;
        case 'number': return pal.number;
        case 'type': return pal.type;
        case 'function': return pal.function;
        case 'builtin': return pal.builtin;
        case 'variable': return pal.variable;
        case 'tag': return pal.tag;
        case 'attribute': return pal.attribute;
        default: return pal.plain;
      }
    }

    for (final m in re.allMatches(text)) {
      if (m.end == m.start) continue;
      if (m.start > pos) {
        out.add(TextSpan(text: text.substring(pos, m.start), style: base));
      }
      var group = 'plain';
      for (var i = 0; i < rules.length; i++) {
        if (m.namedGroup('g$i') != null) {
          group = rules[i].$1;
          break;
        }
      }
      out.add(TextSpan(
        text: m.group(0),
        style: base.copyWith(
          color: colorFor(group),
          fontStyle: group == 'comment' ? FontStyle.italic : null,
        ),
      ));
      pos = m.end;
    }
    if (pos < text.length) {
      out.add(TextSpan(text: text.substring(pos), style: base));
    }
    return out;
  }
}
