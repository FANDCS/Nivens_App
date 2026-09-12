import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Δείχνει το κρυπτογραφημένο (base64) περιεχόμενο ως QR code.
/// Το scan ενός QR reader δίνει το ίδιο base64 string — χρειάζεται ο ίδιος
/// κωδικός για να αποκρυπτογραφηθεί ξανά (μελλοντικό "Εισαγωγή μέσω QR").
void showQrExportDialog({required BuildContext context, required String data}) {
  // Πρακτικό όριο QR (error correction M, ~2900 alphanumeric chars max).
  const maxLength = 2500;
  if (data.length > maxLength) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Η σημείωση είναι πολύ μεγάλη για QR (${data.length} > $maxLength χαρακτήρες). '
          'Δοκίμασε Markdown ή JSON export.',
        ),
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('QR εξαγωγή'),
      content: SizedBox(
        width: 280,
        height: 280,
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Κλείσιμο'),
        ),
      ],
    ),
  );
}
