import 'package:flutter/material.dart';
import 'export_service.dart';
import '../../core/i18n.dart';

/// Αποτέλεσμα επιλογής μορφής εξαγωγής.
class ExportChoice {
  final ExportFormat format;
  final bool encrypted; // true = μέσα σε κρυπτογραφημένο .notesbackup zip

  /// Μόνο για PDF/Εκτύπωση (και μόνο όταν το μενού άνοιξε με
  /// `singleNote: true`): η όψη που διάλεξε ο χρήστης — Προβολή ή
  /// Επεξεργασία. null για όλες τις άλλες μορφές.
  final ExportViewMode? viewMode;
  const ExportChoice({required this.format, required this.encrypted, this.viewMode});
}

/// Καθολικό wrapper για τα bottom sheets αυτού του αρχείου: scrollable +
/// με όριο ύψους, ώστε σε μικρές οθόνες (ή με πολλές επιλογές) ο χρήστης
/// να μπορεί ΠΑΝΤΑ να δει/scroll-άρει ως το τελευταίο στοιχείο, αντί η
/// λίστα να κόβεται εκτός οθόνης.
Widget _scrollableSheet(BuildContext context, Widget child) {
  return SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: child,
      ),
    ),
  );
}

/// Δεύτερο βήμα για PDF / Εκτύπωση: ρωτάει αν θα εξαχθεί η Προβολή (review)
/// ή η λειτουργία Επεξεργασίας (edit). Το [current] σημειώνει σε ποια
/// λειτουργία βρίσκεται τώρα ο χρήστης. Επιστρέφει null αν ακυρώσει.
Future<ExportViewMode?> _askViewMode(BuildContext context, ExportViewMode? current) {
  return showModalBottomSheet<ExportViewMode>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _scrollableSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(context, el: 'Περιεχόμενο εξαγωγής', en: 'Export content'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(tr(context, el: 'Προβολή (review)', en: 'Review (preview mode)')),
            subtitle: Text(tr(context,
                el: 'Αποδοσμένη σημείωση, όπως στην Προβολή',
                en: 'Rendered note, as in Preview')),
            trailing: current == ExportViewMode.review ? const Icon(Icons.check_circle_outline) : null,
            onTap: () => Navigator.of(context).pop(ExportViewMode.review),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr(context, el: 'Επεξεργασία (edit mode)', en: 'Edit mode')),
            subtitle: Text(tr(context,
                el: 'Κείμενο markdown με σύμβολα, όπως στον editor',
                en: 'Markdown text with symbols, as in the editor')),
            trailing: current == ExportViewMode.edit ? const Icon(Icons.check_circle_outline) : null,
            onTap: () => Navigator.of(context).pop(ExportViewMode.edit),
          ),
        ],
      ),
    ),
  );
}

/// Πρώτο βήμα: Nivens (.fnotes) / Markdown (.md) / JSON / PDF / Εκτύπωση /
/// QR (απλά, χωρίς κωδικό) ή ZIP (κρυπτογραφημένο, θα ρωτήσει μετά για
/// κωδικό + εσωτερική μορφή — μόνο .fnotes/JSON, το PDF/εκτύπωση δεν
/// έχουν νόημα μέσα σε zip).
///
/// Με `singleNote: true` (μόνο από τον editor μιας σημείωσης) εμφανίζονται
/// ΕΠΙΠΛΕΟΝ «Αντιγραφή στο πρόχειρο» και «Εικόνα/ες», και το PDF/Εκτύπωση
/// ρωτούν αν θα εξαχθεί η Προβολή (review) ή η Επεξεργασία (edit) — το
/// [currentViewMode] δείχνει σε ποια λειτουργία είναι ο χρήστης αυτή τη
/// στιγμή. Οι μαζικές εξαγωγές («όλες οι σημειώσεις») δεν τα χρησιμοποιούν.
Future<ExportChoice?> showExportFormatMenu({
  required BuildContext context,
  bool allowQr = true,
  bool allowTermbin = true,
  bool singleNote = false,
  ExportViewMode? currentViewMode,
}) async {
  final firstChoice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _scrollableSheet(
      context,
      Column(
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
            title: const Text('Nivens (.fnotes)'),
            subtitle: Text(tr(context, el: "Το φυσικό format της εφαρμογής, χωρίς κωδικό", en: "The app's native format, no password")),
            onTap: () => Navigator.of(context).pop('markdown'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Markdown (.md)'),
            subtitle: Text(tr(context, el: 'Απλό κείμενο markdown, χωρίς μεταδεδομένα — για άλλες εφαρμογές', en: 'Plain markdown text, no metadata — for other apps')),
            onTap: () => Navigator.of(context).pop('md'),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: const Text('JSON'),
            subtitle: Text(tr(context, el: 'Απλό αρχείο, χωρίς κωδικό', en: 'Plain file, no password')),
            onTap: () => Navigator.of(context).pop('json'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF'),
            subtitle: Text(tr(context, el: 'Απλό αρχείο, χωρίς κωδικό', en: 'Plain file, no password')),
            onTap: () => Navigator.of(context).pop('pdf'),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(tr(context, el: 'Εκτύπωση', en: 'Print')),
            subtitle: Text(tr(context, el: 'Διάλογος εκτύπωσης (ή αποθήκευση ως PDF)', en: 'Print dialog (or save as PDF)')),
            onTap: () => Navigator.of(context).pop('print'),
          ),
          if (singleNote) ...[
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(tr(context, el: 'Εικόνα/ες (PNG)', en: 'Image(s) (PNG)')),
              subtitle: Text(tr(context,
                  el: 'Στιγμιότυπο της τρέχουσας λειτουργίας (Προβολή ή Επεξεργασία)',
                  en: 'Screenshot of the current mode (Preview or Edit)')),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text(tr(context, el: 'Αντιγραφή στο πρόχειρο', en: 'Copy to clipboard')),
              subtitle: Text(tr(context,
                  el: 'Κείμενο markdown, όπως στην Επεξεργασία',
                  en: 'Markdown text, as in Edit mode')),
              onTap: () => Navigator.of(context).pop('clipboard'),
            ),
          ],
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
            subtitle: Text(tr(context, el: 'Κρυπτογραφημένο — με κωδικό και επιλογή μορφής', en: 'Encrypted — with password and format choice')),
            onTap: () => Navigator.of(context).pop('zip'),
          ),
        ],
      ),
    ),
  );

  if (firstChoice == null) return null;

  if (firstChoice == 'markdown') return const ExportChoice(format: ExportFormat.markdown, encrypted: false);
  if (firstChoice == 'md') return const ExportChoice(format: ExportFormat.plainMarkdown, encrypted: false);
  if (firstChoice == 'json') return const ExportChoice(format: ExportFormat.json, encrypted: false);
  if (firstChoice == 'qr') return const ExportChoice(format: ExportFormat.qr, encrypted: false);
  if (firstChoice == 'termbin') return const ExportChoice(format: ExportFormat.termbin, encrypted: false);
  if (firstChoice == 'image') return const ExportChoice(format: ExportFormat.image, encrypted: false);
  if (firstChoice == 'clipboard') return const ExportChoice(format: ExportFormat.clipboard, encrypted: false);
  if (firstChoice == 'pdf' || firstChoice == 'print') {
    final format = firstChoice == 'pdf' ? ExportFormat.pdf : ExportFormat.print;
    if (!singleNote) return ExportChoice(format: format, encrypted: false);
    // PDF / Εκτύπωση μιας σημείωσης: ρώτα review ή edit.
    if (!context.mounted) return null;
    final mode = await _askViewMode(context, currentViewMode);
    if (mode == null) return null;
    return ExportChoice(format: format, encrypted: false, viewMode: mode);
  }

  // firstChoice == 'zip' -> ρώτα ΕΠΙΠΛΕΟΝ ποια μορφή θα μπει μέσα στο zip
  if (!context.mounted) return null;
  final innerFormat = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _scrollableSheet(
      context,
      Column(
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
            title: const Text('Nivens (.fnotes)'),
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
