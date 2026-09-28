import 'package:flutter/material.dart';
import '../../core/i18n.dart';

Future<String?> showExportPasswordDialog({
  required BuildContext context,
  required bool hasAppPassphrase,
}) async {
  final controller = TextEditingController();
  final confirmController = TextEditingController();
  String? error;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(tr(context, el: 'Κωδικός για την εξαγωγή', en: 'Export password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasAppPassphrase
                  ? tr(context,
                      el: 'Χρησιμοποίησε τον κωδικό της εφαρμογής σου (ή έναν διαφορετικό) — '
                          'θα χρειαστεί για να ανοίξεις ξανά αυτό το αρχείο.',
                      en: 'Use your app passphrase (or a different one) — '
                          "you'll need it to open this file again.")
                  : tr(context,
                      el: 'Δώσε έναν κωδικό για να προστατέψεις το αρχείο εξαγωγής — '
                          'θα χρειαστεί για να το ανοίξεις ξανά.',
                      en: 'Enter a password to protect the export file — '
                          "you'll need it to open it again."),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(labelText: tr(context, el: 'Κωδικός', en: 'Password')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: tr(context, el: 'Επιβεβαίωση', en: 'Confirm')),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, el: 'Άκυρο', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length < 6) {
                setDialogState(() => error = tr(context, el: 'Χρειάζεται τουλάχιστον 6 χαρακτήρες.', en: 'At least 6 characters are required.'));
                return;
              }
              if (controller.text != confirmController.text) {
                setDialogState(() => error = tr(context, el: 'Οι κωδικοί δεν ταιριάζουν.', en: "Passwords don't match."));
                return;
              }
              Navigator.of(context).pop(controller.text);
            },
            child: Text(tr(context, el: 'Συνέχεια', en: 'Continue')),
          ),
        ],
      ),
    ),
  );
}
