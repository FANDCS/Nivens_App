import 'package:flutter/material.dart';
import 'export_service.dart';

/// Αποτέλεσμα επιλογής μορφής εξαγωγής.
class ExportChoice {
  final ExportFormat format; // json | markdown | qr — το ΠΕΡΙΕΧΟΜΕΝΟ
  final bool encrypted; // true = μέσα σε κρυπτογραφημένο .notesbackup zip
  const ExportChoice({required this.format, required this.encrypted});
}

/// Πρώτο βήμα: JSON / Markdown / QR (απλά, χωρίς κωδικό) ή ZIP
/// (κρυπτογραφημένο, θα ρωτήσει μετά για κωδικό + εσωτερική μορφή).
Future<ExportChoice?> showExportFormatMenu({
  required BuildContext context,
  bool allowQr = true,
}) async {
  final firstChoice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Μορφή εξαγωγής', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Markdown (.md)'),
            subtitle: const Text('Απλό αρχείο, χωρίς κωδικό'),
            onTap: () => Navigator.of(context).pop('markdown'),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: const Text('JSON'),
            subtitle: const Text('Απλό αρχείο, χωρίς κωδικό'),
            onTap: () => Navigator.of(context).pop('json'),
          ),
          if (allowQr)
            ListTile(
              leading: const Icon(Icons.qr_code_2_outlined),
              title: const Text('QR κωδικός'),
              subtitle: const Text('Απλό, χωρίς κωδικό — μόνο για σύντομες σημειώσεις'),
              onTap: () => Navigator.of(context).pop('qr'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: const Text('ZIP με κωδικό'),
            subtitle: const Text('Κρυπτογραφημένο — θα σου ζητήσει κωδικό + μορφή'),
            onTap: () => Navigator.of(context).pop('zip'),
          ),
        ],
      ),
    ),
  );

  if (firstChoice == null) return null;

  if (firstChoice == 'markdown') return const ExportChoice(format: ExportFormat.markdown, encrypted: false);
  if (firstChoice == 'json') return const ExportChoice(format: ExportFormat.json, encrypted: false);
  if (firstChoice == 'qr') return const ExportChoice(format: ExportFormat.qr, encrypted: false);

  // firstChoice == 'zip' -> ρώτα ΕΠΙΠΛΕΟΝ ποια μορφή θα μπει μέσα στο zip
  if (!context.mounted) return null;
  final innerFormat = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Μορφή μέσα στο ZIP', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Markdown (.md)'),
            onTap: () => Navigator.of(context).pop('markdown'),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: const Text('JSON'),
            onTap: () => Navigator.of(context).pop('json'),
          ),
        ],
      ),
    ),
  );
  if (innerFormat == null) return null;
  return ExportChoice(
    format: innerFormat == 'json' ? ExportFormat.json : ExportFormat.markdown,
    encrypted: true,
  );
}
