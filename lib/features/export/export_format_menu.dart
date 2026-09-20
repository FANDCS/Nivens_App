import 'package:flutter/material.dart';
import 'export_service.dart';
import '../../core/i18n.dart';

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
  bool allowTermbin = true,
}) async {
  final firstChoice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, el: 'Μορφή εξαγωγής', en: 'Export format'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Markdown (.md)'),
            subtitle: Text(tr(context, el: 'Απλό αρχείο, χωρίς κωδικό', en: 'Plain file, no password')),
            onTap: () => Navigator.of(context).pop('markdown'),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: const Text('JSON'),
            subtitle: Text(tr(context, el: 'Απλό αρχείο, χωρίς κωδικό', en: 'Plain file, no password')),
            onTap: () => Navigator.of(context).pop('json'),
          ),
          if (allowQr)
            ListTile(
              leading: const Icon(Icons.qr_code_2_outlined),
              title: Text(tr(context, el: 'QR κωδικός', en: 'QR code')),
              subtitle: Text(tr(context, el: 'Απλό, χωρίς κωδικό — μόνο για σύντομες σημειώσεις', en: 'Plain, no password — short notes only')),
              onTap: () => Navigator.of(context).pop('qr'),
            ),
          if (allowTermbin)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(tr(context, el: 'Ανέβασμα στο termbin.com', en: 'Upload to termbin.com')),
              subtitle: Text(tr(context, el: 'Δημόσιο link — χωρίς κρυπτογράφηση', en: 'Public link — no encryption')),
              onTap: () => Navigator.of(context).pop('termbin'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(tr(context, el: 'ZIP με κωδικό', en: 'ZIP with password')),
            subtitle: Text(tr(context, el: 'Κρυπτογραφημένο — θα σου ζητήσει κωδικό + μορφή', en: 'Encrypted — will ask for password + format')),
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
  if (firstChoice == 'termbin') return const ExportChoice(format: ExportFormat.termbin, encrypted: false);

  // firstChoice == 'zip' -> ρώτα ΕΠΙΠΛΕΟΝ ποια μορφή θα μπει μέσα στο zip
  if (!context.mounted) return null;
  final innerFormat = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, el: 'Μορφή μέσα στο ZIP', en: 'Format inside the ZIP'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
