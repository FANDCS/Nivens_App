import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n.dart';

/// Κατάλογος γραμματοσειρών που μπορεί να επιλέξει ο χρήστης ανά σημείωση.
///
/// Όλες κατεβαίνουν/cache-άρονται από το google_fonts. Έχουν επιλεγεί
/// γραμματοσειρές που υποστηρίζουν **ελληνικό** αλφάβητο (Greek subset),
/// ώστε να μη «σπάνε» οι ελληνικές σημειώσεις.
class NoteFonts {
  NoteFonts._();

  /// Η προεπιλογή — το theme της εφαρμογής (χωρίς google font).
  static const defaultFamily = 'Roboto';

  /// name -> κατηγορία (για ομαδοποίηση στο picker)
  static const Map<String, String> catalog = {
    'Roboto': 'Χωρίς πατούρες',
    'Open Sans': 'Χωρίς πατούρες',
    'Noto Sans': 'Χωρίς πατούρες',
    'Lato': 'Χωρίς πατούρες',
    'Montserrat': 'Χωρίς πατούρες',
    'Ubuntu': 'Χωρίς πατούρες',
    'Fira Sans': 'Χωρίς πατούρες',
    'Manrope': 'Χωρίς πατούρες',
    'Mulish': 'Χωρίς πατούρες',
    'Rubik': 'Χωρίς πατούρες',
    'Inter': 'Χωρίς πατούρες',
    'Roboto Serif': 'Με πατούρες',
    'Noto Serif': 'Με πατούρες',
    'Playfair Display': 'Με πατούρες',
    'Literata': 'Με πατούρες',
    'EB Garamond': 'Με πατούρες',
    'Cardo': 'Με πατούρες',
    'Gentium Book Plus': 'Με πατούρες',
    'Roboto Mono': 'Monospace',
    'JetBrains Mono': 'Monospace',
    'Fira Code': 'Monospace',
    'Source Code Pro': 'Monospace',
    'Space Mono': 'Monospace',
    'Comfortaa': 'Διακοσμητικές',
    'Caveat': 'Διακοσμητικές',
    'Patrick Hand': 'Διακοσμητικές',
    'Pacifico': 'Διακοσμητικές',
    'Lobster': 'Διακοσμητικές',
  };

  static List<String> get families => catalog.keys.toList();

  /// Επιστρέφει TextStyle για την οικογένεια `family`, με fallback στο
  /// [base] αν η γραμματοσειρά δεν υπάρχει στον κατάλογο.
  static TextStyle style(String? family, TextStyle? base) {
    final b = base ?? const TextStyle();
    if (family == null || family.isEmpty || family == defaultFamily) return b;
    try {
      return GoogleFonts.getFont(family, textStyle: b);
    } catch (_) {
      return b;
    }
  }

  /// Εφαρμόζει τη γραμματοσειρά σε ολόκληρο TextTheme (για το Markdown
  /// stylesheet της Προβολής).
  static TextTheme textTheme(String? family, TextTheme base) {
    if (family == null || family.isEmpty || family == defaultFamily) return base;
    try {
      return GoogleFonts.getTextTheme(family, base);
    } catch (_) {
      return base;
    }
  }
}

/// Bottom sheet επιλογής γραμματοσειράς με ζωντανή προεπισκόπηση.
Future<String?> showFontPicker({
  required BuildContext context,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final grouped = <String, List<String>>{};
      NoteFonts.catalog.forEach((f, cat) => grouped.putIfAbsent(cat, () => []).add(f));
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(tr(ctx, el: 'Γραμματοσειρά σημείωσης', en: 'Note font'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(entry.key,
                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.primary,
                        )),
              ),
              for (final family in entry.value)
                ListTile(
                  selected: family == current,
                  leading: Icon(family == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
                  title: Text(family,
                      style: NoteFonts.style(family, const TextStyle(fontSize: 18))),
                  subtitle: Text(tr(ctx, el: 'Δοκιμή — Αa Bβ Γγ 123', en: 'Sample — Aa Bb Cc 123'),
                      style: NoteFonts.style(family, const TextStyle(fontSize: 13))),
                  onTap: () => Navigator.of(ctx).pop(family),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
