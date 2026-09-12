import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../notes/models/note.dart';
import 'export_service.dart';

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
      allowedExtensions: ['md', 'txt', 'json', 'pdf', 'notesbackup'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path!;
    final ext = result.files.single.extension?.toLowerCase() ?? '';

    setState(() {
      _isImporting = true;
      _statusMessage = 'Επεξεργασία...';
    });

    try {
      if (ext == 'notesbackup') {
        await _importEncryptedBackup(path);
      } else if (ext == 'json') {
        await _importJson(path);
      } else if (ext == 'pdf') {
        await _importPdf(path);
      } else {
        // md / txt
        await _importPlainText(path, ext);
      }
    } catch (e) {
      setState(() => _statusMessage = 'Σφάλμα: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importEncryptedBackup(String path) async {
    final passwordController = TextEditingController();
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Κωδικός backup'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Κωδικός'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Άκυρο')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(passwordController.text),
              child: const Text('ΟΚ')),
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
        await _saveNoteFromMarkdown(content, title: name.replaceAll(RegExp(r'\.(md|txt)$'), ''));
      }
      count++;
    }
    setState(() => _statusMessage = 'Εισήχθησαν $count σημείωση/σεις.');
  }

  Future<void> _importJson(String path) async {
    final raw = await File(path).readAsString();
    await _saveNoteFromJson(raw);
    setState(() => _statusMessage = 'Εισήχθη 1 σημείωση (JSON).');
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
    setState(() => _statusMessage = 'Εισήχθη PDF ως σημείωση.');
  }

  Future<void> _importPlainText(String path, String ext) async {
    final content = await File(path).readAsString();
    final basename = File(path).uri.pathSegments.last.replaceAll('.$ext', '');
    await _saveNoteFromMarkdown(content, title: basename);
    setState(() => _statusMessage = 'Εισήχθη 1 σημείωση.');
  }

  Future<void> _saveNoteFromMarkdown(String content, {String? title}) async {
    NoteDocument note;
    try {
      note = NoteDocument.fromMarkdownFile(content);
    } catch (_) {
      note = NoteDocument(title: title ?? 'Εισαγωγή', body: content);
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
      title: m['title'] as String? ?? 'Εισαγωγή',
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
      appBar: AppBar(title: const Text('Εισαγωγή')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_outlined, size: 72),
              const SizedBox(height: 16),
              Text('Εισαγωγή σημειώσεων', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Υποστηριζόμενες μορφές:\n'
                '.md / .txt — Markdown ή απλό κείμενο\n'
                '.json — Εξαγωγή σε JSON\n'
                '.pdf — Εξαγωγή κειμένου από PDF\n'
                '.notesbackup — Κρυπτογραφημένο backup (με κωδικό)',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isImporting)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _pickAndImport,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Επιλογή αρχείου'),
                ),
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
