import 'package:flutter/material.dart';

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
        title: const Text('Κωδικός για την εξαγωγή'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasAppPassphrase
                  ? 'Χρησιμοποίησε τον κωδικό της εφαρμογής σου (ή έναν διαφορετικό) — '
                    'θα χρειαστεί για να ανοίξεις ξανά αυτό το αρχείο.'
                  : 'Δώσε έναν κωδικό για να προστατέψεις το αρχείο εξαγωγής — '
                    'θα χρειαστεί για να το ανοίξεις ξανά.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Κωδικός'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Επιβεβαίωση'),
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
            child: const Text('Άκυρο'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length < 6) {
                setDialogState(() => error = 'Χρειάζεται τουλάχιστον 6 χαρακτήρες.');
                return;
              }
              if (controller.text != confirmController.text) {
                setDialogState(() => error = 'Οι κωδικοί δεν ταιριάζουν.');
                return;
              }
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('Συνέχεια'),
          ),
        ],
      ),
    ),
  );
}
