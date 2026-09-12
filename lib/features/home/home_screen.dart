import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../notes/note_editor_screen.dart';
import '../notes/models/note.dart';
import '../daily_log/daily_entry_dialog.dart';
import '../daily_log/daily_stats_screen.dart';
import '../settings/settings_screen.dart';
import '../export/export_service.dart';
import '../export/export_password_dialog.dart';
import '../export/export_format_menu.dart';
import '../export/import_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase database;
  final EncryptionService encryptionService;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final Locale? currentLocale;

  const HomeScreen({
    super.key,
    required this.database,
    required this.encryptionService,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  bool _isExportingAll = false;

  void _openNoteEditor({String? noteId}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NoteEditorScreen(
        database: widget.database,
        encryptionService: widget.encryptionService,
        existingNoteId: noteId,
      ),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        encryptionService: widget.encryptionService,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
      ),
    ));
  }

  void _openImport() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImportScreen(database: widget.database, encryptionService: widget.encryptionService),
    ));
  }

  void _openStats() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DailyStatsScreen(database: widget.database, encryptionService: widget.encryptionService),
    ));
  }

  Future<void> _exportAllNotes() async {
    final notes = await (widget.database.select(widget.database.notes)
          ..where((n) => n.isDeleted.equals(false)))
        .get();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Δεν υπάρχουν σημειώσεις.')));
      return;
    }
    final choice = await showExportFormatMenu(context: context, allowQr: false);
    if (choice == null || !mounted) return;

    String? password;
    if (choice.encrypted) {
      password = await showExportPasswordDialog(
        context: context,
        hasAppPassphrase: await widget.encryptionService.hasPassphraseProtection(),
      );
      if (password == null || !mounted) return;
    }

    setState(() => _isExportingAll = true);
    try {
      final files = <String, String>{};
      for (final row in notes) {
        final decrypted = await widget.encryptionService.decryptText(row.encryptedContent);
        final noteDoc = NoteDocument.fromMarkdownFile(decrypted);
        final safe = noteDoc.title.replaceAll(RegExp(r'[^\w\-]+'), '_');
        if (choice.format == ExportFormat.json) {
          files['$safe-${noteDoc.id.substring(0, 8)}.json'] = jsonEncode({
            'id': noteDoc.id, 'title': noteDoc.title, 'tags': noteDoc.tags,
            'createdAt': noteDoc.createdAt.toIso8601String(),
            'updatedAt': noteDoc.updatedAt.toIso8601String(), 'body': noteDoc.body,
          });
        } else {
          files['$safe-${noteDoc.id.substring(0, 8)}.md'] = decrypted;
        }
      }
      final ext = choice.format == ExportFormat.json ? 'json' : 'md';
      String path;
      if (choice.encrypted) {
        path = await ExportService().exportEncryptedZip(files: files, password: password!, outputNamePrefix: 'all_notes');
      } else {
        // Πολλά αρχεία χωρίς zip — αποθηκεύουμε ένα-ένα
        final svc = ExportService();
        final paths = <String>[];
        for (final e in files.entries) {
          paths.add(await svc.exportPlainFile(content: e.value, filename: e.key));
        }
        path = paths.first.replaceAll(RegExp(r'[^/]+$'), '(${paths.length} αρχεία)');
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Εξήχθη: $path')));
    } finally {
      if (mounted) setState(() => _isExportingAll = false);
    }
  }

  Future<void> _exportAllDaily() async {
    final entries = await widget.database.select(widget.database.dailyEntries).get();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Δεν υπάρχουν καταχωρήσεις.')));
      return;
    }
    final choice = await showExportFormatMenu(context: context, allowQr: false);
    if (choice == null || !mounted) return;

    String? password;
    if (choice.encrypted) {
      password = await showExportPasswordDialog(
        context: context,
        hasAppPassphrase: await widget.encryptionService.hasPassphraseProtection(),
      );
      if (password == null || !mounted) return;
    }

    setState(() => _isExportingAll = true);
    try {
      final sorted = [...entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      String content;
      String filename;
      if (choice.format == ExportFormat.json) {
        final list = [];
        for (final e in sorted) {
          list.add({'timestamp': e.timestamp.toIso8601String(), 'text': await widget.encryptionService.decryptText(e.encryptedText), 'tag': e.tag, 'weight': e.weight});
        }
        content = jsonEncode(list);
        filename = 'daily_log.json';
      } else {
        final buf = StringBuffer();
        for (final e in sorted) {
          final text = await widget.encryptionService.decryptText(e.encryptedText);
          buf.writeln('## ${e.timestamp.toIso8601String()}${e.tag != null ? ' [${e.tag}]' : ''}');
          buf.writeln(text);
          buf.writeln('Βαρύτητα: ${e.weight}\n');
        }
        content = buf.toString();
        filename = 'daily_log.md';
      }
      String path;
      if (choice.encrypted) {
        path = await ExportService().exportEncryptedZip(files: {filename: content}, password: password!, outputNamePrefix: 'daily_log');
      } else {
        path = await ExportService().exportPlainFile(content: content, filename: filename);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Εξήχθη: $path')));
    } finally {
      if (mounted) setState(() => _isExportingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _NotesTab(database: widget.database, onTapNote: (id) => _openNoteEditor(noteId: id)),
      _DailyLogTab(database: widget.database, encryptionService: widget.encryptionService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? 'Σημειώσεις' : 'Καθημερινά'),
        actions: [
          if (_tabIndex == 0)
            IconButton(icon: const Icon(Icons.upload_file_outlined), tooltip: 'Εισαγωγή', onPressed: _openImport),
          if (_tabIndex == 1)
            IconButton(icon: const Icon(Icons.bar_chart_outlined), tooltip: 'Στατιστικά', onPressed: _openStats),
          IconButton(
            icon: _isExportingAll
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_outlined),
            tooltip: _tabIndex == 0 ? 'Εξαγωγή σημειώσεων' : 'Εξαγωγή καθημερινών',
            onPressed: _isExportingAll ? null : (_tabIndex == 0 ? _exportAllNotes : _exportAllDaily),
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _openSettings),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_outlined), selectedIcon: Icon(Icons.note), label: 'Σημειώσεις'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Καθημερινά'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabIndex == 0) {
            _openNoteEditor();
          } else {
            showAddDailyEntryDialog(context: context, database: widget.database, encryptionService: widget.encryptionService);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final AppDatabase database;
  final void Function(String) onTapNote;
  const _NotesTab({required this.database, required this.onTapNote});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: (database.select(database.notes)..where((n) => n.isDeleted.equals(false))).watch(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return const Center(child: Text('Δεν υπάρχουν ακόμα σημειώσεις.\nΠάτα + για να φτιάξεις μία.', textAlign: TextAlign.center));
        }
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(notes[i].title.isEmpty ? '(χωρίς τίτλο)' : notes[i].title),
            subtitle: Text(notes[i].updatedAt.toLocal().toString().substring(0, 16)),
            onTap: () => onTapNote(notes[i].id),
          ),
        );
      },
    );
  }
}

class _DailyLogTab extends StatelessWidget {
  final AppDatabase database;
  final EncryptionService encryptionService;
  const _DailyLogTab({required this.database, required this.encryptionService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: database.select(database.dailyEntries).watch(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('Δεν υπάρχουν ακόμα καταχωρήσεις.\nΠάτα + για να προσθέσεις μία.', textAlign: TextAlign.center));
        }
        final sorted = [...entries]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return ListView.builder(
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final e = sorted[i];
            return FutureBuilder<String>(
              future: encryptionService.decryptText(e.encryptedText),
              builder: (context, ts) => ListTile(
                leading: e.tag != null ? Chip(label: Text(e.tag!)) : null,
                title: Text(ts.data ?? '...'),
                subtitle: Text(e.timestamp.toLocal().toString().substring(0, 16)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('●' * e.weight, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => deleteDailyEntry(database: database, id: e.id),
                  ),
                ]),
                onTap: () => showAddDailyEntryDialog(context: context, database: database, encryptionService: encryptionService, existing: e),
              ),
            );
          },
        );
      },
    );
  }
}
