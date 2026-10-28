import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/text_encoding.dart';

/// Τίτλος ομάδας κωδικοποιήσεων (βλ. [TextEncoding.group]) στη γλώσσα της
/// εφαρμογής.
String encodingGroupLabel(BuildContext context, String group) {
  switch (group) {
    case 'Unicode':
      return 'Unicode';
    case 'Greek':
      return tr(context, el: 'Ελληνικά', en: 'Greek');
    case 'Western European':
      return tr(context, el: 'Δυτικοευρωπαϊκά', en: 'Western European');
    case 'Central European':
      return tr(context, el: 'Κεντρικής/Ανατολικής Ευρώπης', en: 'Central European');
    case 'Baltic':
      return tr(context, el: 'Βαλτικά', en: 'Baltic');
    case 'Cyrillic':
      return tr(context, el: 'Κυριλλικά', en: 'Cyrillic');
    case 'Turkish':
      return tr(context, el: 'Τουρκικά', en: 'Turkish');
    case 'Hebrew':
      return tr(context, el: 'Εβραϊκά', en: 'Hebrew');
    case 'Arabic':
      return tr(context, el: 'Αραβικά', en: 'Arabic');
    case 'Vietnamese / Thai':
      return tr(context, el: 'Βιετναμέζικα / Ταϊλανδέζικα', en: 'Vietnamese / Thai');
    default:
      return group;
  }
}

/// Διάλογος επιλογής κωδικοποίησης, ομαδοποιημένος ανά οικογένεια
/// (Unicode, Ελληνικά, Δυτικοευρωπαϊκά, Κυριλλικά, ...) και scrollable —
/// με πάνω από 50 κωδικοποιήσεις μια επίπεδη λίστα θα ήταν δυσκολοδιάβαστη.
/// Επιστρέφει null αν ο χρήστης ακυρώσει.
Future<TextEncoding?> showEncodingPicker({
  required BuildContext context,
  required String title,
  TextEncoding? current,
}) {
  return showDialog<TextEncoding>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final children = <Widget>[];
      String? lastGroup;
      for (final enc in TextEncoding.all) {
        if (enc.group != lastGroup) {
          lastGroup = enc.group;
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Text(
              encodingGroupLabel(ctx, enc.group),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ));
        }
        final selected = enc == current;
        children.add(ListTile(
          dense: true,
          selected: selected,
          title: Text(enc.label),
          trailing: selected ? const Icon(Icons.check, size: 18) : null,
          onTap: () => Navigator.of(ctx).pop(enc),
        ));
      }
      return AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.only(top: 4, bottom: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(shrinkWrap: true, children: children),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr(ctx, el: 'Άκυρο', en: 'Cancel')),
          ),
        ],
      );
    },
  );
}
