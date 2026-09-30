import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/i18n.dart';
import '../../core/storage/app_database.dart';
import '../notes/models/note.dart';
import '../pdf/pdf_viewer_screen.dart';
import 'encoding_converter_screen.dart';
import 'export_service.dart';
import 'qr_import_dialog.dart';
import '../import/doc_reader.dart';
import '../import/docx_reader.dart';

class ImportScreen extends StatefulWidget {
  final AppDatabase database;
  final EncryptionService encryptionService;

  const ImportScreen({
    super.key,
    required this.database,
    required this.encryptionService,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String? _statusMessage;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'fnotes', 'json', 'pdf', 'doc', 'docx', 'notesbackup'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path!;
    final ext = result.files.single.extension?.toLowerCase() ?? '';

    setState(() {
      _isImporting = true;
      _statusMessage = tr(context, el: 'Επεξεργασία...', en: 'Processing...');
    });

    try {
      if (ext == 'notesbackup') {
        await _importEncryptedBackup(path);
      } else if (ext == 'json') {
        await _importJson(path);
      } else if (ext == 'doc' || ext == 'docx') {
        await _importWordFile(path, ext);
      } else if (ext == 'pdf') {
        final viewOnly = await _askPdfViewOnly();
        if (viewOnly == true) {
          if (mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PdfViewerScreen(filePath: path, title: File(path).uri.pathSegments.last),
            ));
          }
          setState(() => _statusMessage = null);
          return;
        }
        await _importPdf(path);
      } else {
        // md / txt / fnotes
        await _importPlainText(path, ext);
      }
    } catch (e) {
      setState(() => _statusMessage = '${tr(context, el: 'Σφάλμα', en: 'Error')}: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importWordFile(String path, String ext) async {
    final file = File(path);
    if (ext == 'doc') {
      final content = await DocReader.readFile(file);
      await _saveNoteFromMarkdown(content.markdown, title: content.title);
    } else {
      final docx = await DocxReader.readFile(file);
      await _saveNoteFromMarkdown(
        docx.markdownWithImages,
        title: File(path).uri.pathSegments.last.replaceAll('.docx', ''),
      );
    }
    setState(() => _statusMessage = tr(context, el: 'Εισήχθη το έγγραφο ως σημείωση.', en: 'Imported the document as a note.'));
  }

  Future<void> _importViaQr() async {
    final raw = await showQrImportDialog(context: context);
    if (raw == null || !mounted) return;
    await _saveNoteFromMarkdown(raw);
    setState(() => _statusMessage = tr(context, el: 'Εισήχθη 1 σημείωση (QR).', en: 'Imported 1 note (QR).'));
  }

  Future<void> _importEncryptedBackup(String path) async {
    final passwordController = TextEditingController();
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, el: 'Κωδικός backup', en: 'Backup password')),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: tr(context, el: 'Κωδικός', en: 'Password')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(passwordController.text),
              child: Text('OK')),
        ],
      ),
    );
    if (pw == null || pw.isEmpty) return;

    final bytes = await File(path).readAsBytes();
    final files = await ExportService().decryptExportedZip(fileBytes: bytes, password: pw);
    int count = 0;
    for (final entry in files.entries) {
      final name = entry.key;
      final content = entry.value;
      if (name.endsWith('.json')) {
        await _saveNoteFromJson(content);
      } else {
        await _saveNoteFromMarkdown(content, title: name.replaceAll(RegExp(r'\.(md|txt|fnotes)$'), ''));
      }
      count++;
    }
    setState(() => _statusMessage = tr(context, el: 'Εισήχθησαν $count σημείωση/σεις.', en: 'Imported $count note(s).'));
  }

  Future<void> _importJson(String path) async {
    final raw = await File(path).readAsString();
    await _saveNoteFromJson(raw);
    setState(() => _statusMessage = tr(context, el: 'Εισήχθη 1 σημείωση (JSON).', en: 'Imported 1 note (JSON).'));
  }

  Future<bool?> _askPdfViewOnly() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr(context, el: 'Αρχείο PDF', en: 'PDF file')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_outlined), const SizedBox(width: 12), Text(tr(context, el: 'Προβολή ως PDF', en: 'View as PDF')),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Row(children: [
              const Icon(Icons.text_snippet_outlined), const SizedBox(width: 12), Text(tr(context, el: 'Εξαγωγή κειμένου σε νέα σημείωση', en: 'Extract text into a new note')),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _importPdf(String path) async {
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final buffer = StringBuffer();
    for (var i = 0; i < doc.pages.count; i++) {
      buffer.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
    }
    doc.dispose();
    final basename = File(path).uri.pathSegments.last.replaceAll('.pdf', '');
    await _saveNoteFromMarkdown(buffer.toString(), title: basename);
    setState(() => _statusMessage = tr(context, el: 'Εισήχθη PDF ως σημείωση.', en: 'Imported PDF as a note.'));
  }

  Future<void> _importPlainText(String path, String ext) async {
    final content = await File(path).readAsString();
    final basename = File(path).uri.pathSegments.last.replaceAll('.$ext', '');
    await _saveNoteFromMarkdown(content, title: basename);
    setState(() => _statusMessage = tr(context, el: 'Εισήχθη 1 σημείωση.', en: 'Imported 1 note.'));
  }

  Future<void> _saveNoteFromMarkdown(String content, {String? title}) async {
    NoteDocument note;
    try {
      note = NoteDocument.fromMarkdownFile(content);
    } catch (_) {
      note = NoteDocument(title: title ?? tr(context, el: 'Εισαγωγή', en: 'Import'), body: content);
    }
    note.id = const Uuid().v4(); // νέο id για να μην συγκρουστεί
    final encrypted = await widget.encryptionService.encryptText(note.toMarkdownFile());
    await widget.database.into(widget.database.notes).insertOnConflictUpdate(
      NotesCompanion(
        id: Value(note.id),
        title: Value(note.title),
        encryptedContent: Value(encrypted),
        updatedAt: Value(note.updatedAt),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> _saveNoteFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      for (final item in decoded) {
        await _saveNoteFromJsonMap(item as Map<String, dynamic>);
      }
    } else {
      await _saveNoteFromJsonMap(decoded as Map<String, dynamic>);
    }
  }

  Future<void> _saveNoteFromJsonMap(Map<String, dynamic> m) async {
    final note = NoteDocument(
      title: m['title'] as String? ?? tr(context, el: 'Εισαγωγή', en: 'Import'),
      body: m['body'] as String? ?? '',
      tags: (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
    final encrypted = await widget.encryptionService.encryptText(note.toMarkdownFile());
    await widget.database.into(widget.database.notes).insertOnConflictUpdate(
      NotesCompanion(
        id: Value(note.id),
        title: Value(note.title),
        encryptedContent: Value(encrypted),
        updatedAt: Value(note.updatedAt),
        isSynced: const Value(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Εισαγωγή', en: 'Import'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_outlined, size: 72),
              const SizedBox(height: 16),
              Text(tr(context, el: 'Εισαγωγή σημειώσεων', en: 'Import notes'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                tr(context,
                    el: 'Υποστηριζόμενες μορφές:\n'
                        '.fnotes — Το φυσικό format της εφαρμογής\n'
                        '.md / .txt — Markdown ή απλό κείμενο\n'
                        '.doc / .docx — Έγγραφο Word (μόνο κείμενο)\n'
                        '.json — Εξαγωγή σε JSON\n'
                        '.pdf — Προβολή ως PDF ή εξαγωγή κειμένου\n'
                        '.notesbackup — Κρυπτογραφημένο backup (με κωδικό)\n'
                        'QR — από κάμερα ή επικόλληση',
                    en: 'Supported formats:\n'
                        '.fnotes — The app\'s native format\n'
                        '.md / .txt — Markdown or plain text\n'
                        '.doc / .docx — Word document (text only)\n'
                        '.json — JSON export\n'
                        '.pdf — View as PDF or extract text\n'
                        '.notesbackup — Encrypted backup (password)\n'
                        'QR — from camera or paste'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isImporting)
                const CircularProgressIndicator()
              else ...[
                FilledButton.icon(
                  onPressed: _pickAndImport,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(tr(context, el: 'Επιλογή αρχείου', en: 'Choose file')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _importViaQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(tr(context, el: 'Εισαγωγή μέσω QR', en: 'Import via QR')),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EncodingConverterScreen()),
                  ),
                  icon: const Icon(Icons.translate_outlined),
                  label: Text(tr(context, el: 'Μετατροπή κωδικοποίησης αρχείου', en: 'Convert file encoding')),
                ),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(_statusMessage!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
