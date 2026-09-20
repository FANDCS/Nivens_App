import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/nivens_folder.dart';
import '../categories/category_picker.dart';
import '../clipart/clip_art_picker.dart';
import '../drawing/drawing_screen.dart';
import '../export/export_service.dart';
import '../export/export_password_dialog.dart';
import '../export/export_format_menu.dart';
import '../export/qr_export_dialog.dart';
import '../export/termbin_service.dart';
import '../import/docx_reader.dart';
import '../pdf/pdf_viewer_screen.dart';
import 'models/note.dart';
import 'note_fonts.dart';
import '../../core/i18n.dart';

/// Regex που ταιριάζει markdown εικόνα με προαιρετικό attribute μεγέθους:
/// ![alt](path "w=NN")  → NN = πλάτος ως ποσοστό (%) του διαθέσιμου χώρου.
final RegExp _imageWithSizeRegex =
    RegExp(r'!\[([^\]]*)\]\(([^)"\s]+)(?:\s+"w=(\d{1,3})")?\)');

enum _PdfAction { view, extractText }

class NoteEditorScreen extends StatefulWidget {
  final AppDatabase database;
  final EncryptionService encryptionService;
  final String? existingNoteId;
  final String? initialContent;
  final String? initialTitle;

  const NoteEditorScreen({
    super.key,
    required this.database,
    required this.encryptionService,
    this.existingNoteId,
    this.initialContent,
    this.initialTitle,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  NoteDocument? _note;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExporting = false;

  /// false = edit (raw markdown), true = preview (rendered)
  bool _previewMode = false;

  // ── Ζουμ στην Προβολή (preview mode) ────────────────────────────────────
  final TransformationController _zoomController = TransformationController();
  final GlobalKey _previewRepaintKey = GlobalKey();
  bool _isFlatteningDrawing = false;
  double _zoomLevel = 1.0;

  /// Bytes του overlay (ζωγραφιά πάνω από όλα) — κρατιούνται στη μνήμη για
  /// γρήγορη απόδοση στο Stack της Προβολής.
  Uint8List? _overlayBytes;

  /// Προσωρινή απόκρυψη του overlay (π.χ. για να δεις τι κρύβει από κάτω).
  bool _overlayVisible = true;

  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  Size _previewViewportSize = Size.zero;
  TapDownDetails? _lastDoubleTapDetails;

  // ── Undo/Redo history ───────────────────────────────────────────────────────
  final List<String> _history = [''];
  int _historyIndex = 0;
  bool _suppressHistory = false;

  @override
  void initState() {
    super.initState();
    _load();
    _bodyController.addListener(_recordHistory);
  }

  void _recordHistory() {
    if (_suppressHistory) return;
    final text = _bodyController.text;
    if (_history.isEmpty || _history[_historyIndex] == text) return;
    // Αν έχουμε κάνει undo, κόβουμε το μέλλον
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(text);
    if (_history.length > 300) { _history.removeAt(0); } else { _historyIndex++; }
    if (mounted) setState(() {});
  }

  void _undo() {
    if (_historyIndex <= 0) return;
    _suppressHistory = true;
    _historyIndex--;
    _bodyController.text = _history[_historyIndex];
    _bodyController.selection = TextSelection.collapsed(offset: _bodyController.text.length);
    _suppressHistory = false;
    setState(() {});
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    _suppressHistory = true;
    _historyIndex++;
    _bodyController.text = _history[_historyIndex];
    _bodyController.selection = TextSelection.collapsed(offset: _bodyController.text.length);
    _suppressHistory = false;
    setState(() {});
  }

  Future<void> _load() async {
    if (widget.initialContent != null) {
      _note = NoteDocument(title: widget.initialTitle ?? '');
      _titleController.text = _note!.title;
      _bodyController.text = widget.initialContent!;
    } else if (widget.existingNoteId != null) {
      final row = await (widget.database.select(widget.database.notes)
            ..where((n) => n.id.equals(widget.existingNoteId!)))
          .getSingle();
      final decrypted = await widget.encryptionService.decryptText(row.encryptedContent);
      _note = NoteDocument.fromMarkdownFile(decrypted);
      _titleController.text = _note!.title;
      _bodyController.text = _note!.body;
    } else {
      _note = NoteDocument(title: '');
    }
    await _loadOverlay();
    _history[0] = _bodyController.text;
    setState(() => _isLoading = false);
  }

  Future<void> _loadOverlay() async {
    final path = _note?.overlayPath;
    if (path == null) { _overlayBytes = null; return; }
    try {
      final f = File(path);
      _overlayBytes = await f.exists() ? await f.readAsBytes() : null;
    } catch (_) {
      _overlayBytes = null;
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty && _bodyController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    _note!.title = _titleController.text.trim().isEmpty ? 'Χωρίς τίτλο' : _titleController.text.trim();
    _note!.body = _bodyController.text;
    _note!.updatedAt = DateTime.now().toUtc();
    final encrypted = await widget.encryptionService.encryptText(_note!.toMarkdownFile());
    await widget.database.into(widget.database.notes).insertOnConflictUpdate(
      NotesCompanion(
        id: Value(_note!.id),
        title: Value(_note!.title),
        encryptedContent: Value(encrypted),
        updatedAt: Value(_note!.updatedAt),
        isSynced: const Value(false),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, el: 'Διαγραφή σημείωσης', en: 'Delete note')),
        content: Text(tr(context, el: 'Είσαι σίγουρος;', en: 'Are you sure?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr(context, el: 'Διαγραφή', en: 'Delete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await (widget.database.update(widget.database.notes)
          ..where((n) => n.id.equals(_note!.id)))
        .write(const NotesCompanion(isDeleted: Value(true)));
    if (mounted) Navigator.of(context).pop();
  }

  // ── FORMATTING ─────────────────────────────────────────────────────────────

  /// Wrap toggle: αν επιλεγμένο κείμενο ΗΔΗ έχει το wrap → αφαιρεί. Αλλιώς → προσθέτει.
  void _toggleWrap(String before, String after) {
    final ctrl = _bodyController;
    final sel = ctrl.selection;
    if (!sel.isValid) {
      // Αν δεν υπάρχει επιλογή, εισάγουμε στο cursor
      final pos = sel.isValid ? sel.baseOffset : ctrl.text.length;
      final newText = ctrl.text.substring(0, pos) + before + after + ctrl.text.substring(pos);
      ctrl.text = newText;
      ctrl.selection = TextSelection.collapsed(offset: pos + before.length);
      return;
    }
    final text = ctrl.text;
    final selected = sel.textInside(text);
    final hasWrap = selected.startsWith(before) && selected.endsWith(after)
        && selected.length >= before.length + after.length;
    if (hasWrap) {
      final inner = selected.substring(before.length, selected.length - after.length);
      ctrl.text = text.replaceRange(sel.start, sel.end, inner);
      ctrl.selection = TextSelection(baseOffset: sel.start, extentOffset: sel.start + inner.length);
    } else {
      final wrapped = '$before$selected$after';
      ctrl.text = text.replaceRange(sel.start, sel.end, wrapped);
      ctrl.selection = TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      );
    }
  }

  /// Toggle line prefix: αφαιρεί αν ΗΔΗ υπάρχει, αλλιώς προσθέτει.
  void _togglePrefix(String prefix) {
    final ctrl = _bodyController;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final caretPos = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', caretPos - 1) + 1;
    final lineEndIdx = text.indexOf('\n', caretPos);
    final lineEnd = lineEndIdx == -1 ? text.length : lineEndIdx;
    final line = text.substring(lineStart, lineEnd);
    String newLine;
    if (line.startsWith(prefix)) {
      newLine = line.substring(prefix.length);
    } else {
      newLine = '$prefix$line';
    }
    ctrl.text = text.replaceRange(lineStart, lineEnd, newLine);
    final newCaret = (lineStart + prefix.length).clamp(0, ctrl.text.length);
    ctrl.selection = TextSelection.collapsed(offset: line.startsWith(prefix) ? lineStart : newCaret);
  }

  bool _selectionWrapped(String before, String after) {
    final sel = _bodyController.selection;
    if (!sel.isValid || sel.isCollapsed) return false;
    final selected = sel.textInside(_bodyController.text);
    return selected.startsWith(before) && selected.endsWith(after)
        && selected.length >= before.length + after.length;
  }

  // ── MEDIA ──────────────────────────────────────────────────────────────────

  /// Ζητά από τον χρήστη πόσο μεγάλη να είναι μια εικόνα πριν εισαχθεί
  /// (ή για να αλλάξει μέγεθος σε ήδη υπάρχουσα). Επιστρέφει ποσοστό 10-100.
  Future<int?> _pickImageWidthPercent({int initial = 60}) async {
    int value = initial;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Μέγεθος εικόνας'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value% του πλάτους', style: Theme.of(ctx).textTheme.bodyMedium),
              Slider(
                value: value.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                label: '$value%',
                onChanged: (v) => setS(() => value = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final preset in [25, 50, 75, 100])
                    ActionChip(
                      label: Text('$preset%'),
                      onPressed: () => setS(() => value = preset),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Άκυρο')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(value), child: const Text('ΟΚ')),
          ],
        ),
      ),
    );
  }

  Future<void> _insertImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final widthPercent = await _pickImageWidthPercent();
    if (widthPercent == null || !mounted) return;
    final dir = await NivensFolder.sub('images');
    final dest = File(p.join(dir.path, p.basename(picked.path)));
    await File(picked.path).copy(dest.path);
    _insertAtCursor('\n![εικόνα](${dest.path} "w=$widthPercent")\n');
  }

  Future<void> _openDrawing() async {
    final result = await Navigator.of(context).push<DrawingResult>(
      MaterialPageRoute(builder: (_) => const DrawingScreen(title: 'Νέο σχέδιο'), fullscreenDialog: true),
    );
    if (result == null || !mounted) return;
    final widthPercent = await _pickImageWidthPercent();
    if (widthPercent == null || !mounted) return;
    final dir = await NivensFolder.sub('drawings');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final imgFile = File(p.join(dir.path, 'drawing_$ts.png'));
    await imgFile.writeAsBytes(result.pngBytes);
    _insertAtCursor('\n![σχέδιο](${imgFile.path} "w=$widthPercent")\n');
  }

  /// "Ζωγραφική πάνω σε όλα": τραβάει στιγμιότυπο ΟΛΟΥ του αποδοσμένου
  /// περιεχομένου (κείμενο + εικόνες όπως φαίνονται στην Προβολή) και το
  /// περνάει ως ΦΟΝΤΟ στην οθόνη σχεδίασης. Ό,τι ζωγραφίσεις αποθηκεύεται
  /// ως ξεχωριστό PNG με ΔΙΑΦΑΝΟ φόντο (overlay layer) και αποδίδεται
  /// πάντα στο ΥΨΗΛΟΤΕΡΟ επίπεδο της Προβολής — πάνω από κείμενο και
  /// πολυμέσα — χωρίς να αλλοιώνει το markdown της σημείωσης.
  Future<void> _drawOverEverything() async {
    if (!_previewMode) {
      setState(() => _previewMode = true);
      // Δώσε ένα frame να χτιστεί η Προβολή πριν το snapshot.
      await Future.delayed(const Duration(milliseconds: 60));
    }
    setState(() => _isFlatteningDrawing = true);
    Uint8List? background;
    try {
      final boundary =
          _previewRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        background = byteData?.buffer.asUint8List();
      }
    } catch (_) {
      // Αν αποτύχει το snapshot, ανοίγει απλά κενή σελίδα σχεδίασης.
    } finally {
      if (mounted) setState(() => _isFlatteningDrawing = false);
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<DrawingResult>(
      MaterialPageRoute(
        builder: (_) => DrawingScreen(
          title: 'Ζωγραφική πάνω σε όλα',
          backgroundImageBytes: background,
          existingOverlayBytes: _overlayBytes,
          transparentResult: true,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) return;
    final dir = await NivensFolder.sub('drawings');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final imgFile = File(p.join(dir.path, 'overlay_${_note!.id}_$ts.png'));
    await imgFile.writeAsBytes(result.pngBytes);
    // ΔΕΝ μπαίνει στο markdown: αποθηκεύεται ως ξεχωριστό, διάφανο layer
    // που ζωγραφίζεται ΠΑΝΩ από κείμενο και πολυμέσα στην Προβολή.
    setState(() {
      _note!.overlayPath = imgFile.path;
      _overlayBytes = result.pngBytes;
      _overlayVisible = true;
    });
  }

  Future<void> _clearOverlay() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, el: 'Διαγραφή ζωγραφιάς', en: 'Delete drawing')),
        content: Text(tr(context, el: 'Να αφαιρεθεί το επίπεδο ζωγραφικής από τη σημείωση;', en: 'Remove the drawing layer from this note?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr(context, el: 'Διαγραφή', en: 'Delete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _note!.overlayPath = null;
      _overlayBytes = null;
    });
  }

  Future<void> _pickFont() async {
    final chosen = await showFontPicker(context: context, current: _note!.font);
    if (chosen == null || !mounted) return;
    setState(() => _note!.font = chosen);
  }

  Future<void> _insertClipArt() async {
    final result = await Navigator.of(context).push<ClipArtResult>(
      MaterialPageRoute(builder: (_) => const ClipArtPickerScreen(), fullscreenDialog: true),
    );
    if (result == null || !mounted) return;
    final dir = await NivensFolder.sub('clipart');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final imgFile = File(p.join(dir.path, 'clipart_$ts.png'));
    await imgFile.writeAsBytes(result.pngBytes);
    _insertAtCursor('\n![clip art](${imgFile.path} "w=25")\n');
  }

  /// Αλλάζει το πλάτος μιας ήδη εισαγμένης εικόνας (tap πάνω της στην
  /// Προβολή). Βρίσκει τη γραμμή markdown με το ίδιο path και ενημερώνει
  /// (ή προσθέτει) το attribute "w=NN".
  Future<void> _resizeExistingImage(String path) async {
    final match = _imageWithSizeRegex.firstMatch(_bodyController.text.split('\n')
        .firstWhere((l) => l.contains(path), orElse: () => ''));
    final current = match != null && match.group(3) != null ? int.tryParse(match.group(3)!) ?? 60 : 60;
    final widthPercent = await _pickImageWidthPercent(initial: current);
    if (widthPercent == null) return;
    final text = _bodyController.text;
    final updated = text.replaceAllMapped(_imageWithSizeRegex, (m) {
      if (m.group(2) != path) return m[0]!;
      final alt = m.group(1) ?? '';
      return '![$alt]($path "w=$widthPercent")';
    });
    setState(() => _bodyController.text = updated);
  }

  void _insertAtCursor(String text) {
    final ctrl = _bodyController;
    final pos = ctrl.selection.isValid ? ctrl.selection.baseOffset : ctrl.text.length;
    ctrl.text = ctrl.text.substring(0, pos) + text + ctrl.text.substring(pos);
    ctrl.selection = TextSelection.collapsed(offset: pos + text.length);
  }

  // ── IMPORT ─────────────────────────────────────────────────────────────────

  Future<_PdfAction?> _pickPdfAction() {
    return showDialog<_PdfAction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr(context, el: 'Αρχείο PDF', en: 'PDF file')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_PdfAction.view),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_outlined), const SizedBox(width: 12),
              Text(tr(context, el: 'Προβολή ως PDF', en: 'View as PDF')),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_PdfAction.extractText),
            child: Row(children: [
              const Icon(Icons.text_snippet_outlined), const SizedBox(width: 12),
              Text(tr(context, el: 'Εξαγωγή κειμένου στη σημείωση', en: 'Extract text into note')),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'json', 'pdf', 'docx', 'rtf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final ext = result.files.single.extension?.toLowerCase() ?? '';
    try {
      String content;
      if (ext == 'pdf') {
        final choice = await _pickPdfAction();
        if (choice == null) return;
        if (choice == _PdfAction.view) {
          if (mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PdfViewerScreen(filePath: file.path, title: p.basename(file.path)),
            ));
          }
          return;
        }
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(doc);
        final buf = StringBuffer();
        for (var i = 0; i < doc.pages.count; i++) {
          buf.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
        }
        doc.dispose();
        content = buf.toString();
      } else if (ext == 'docx') {
        final docx = await DocxReader.readFile(file);
        content = docx.markdownWithImages;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = p.basenameWithoutExtension(file.path);
        }
      } else if (ext == 'doc') {
        throw const FormatException(
            'Το παλιό .doc (Word 97-2003) δεν υποστηρίζεται — αποθήκευσέ το ως .docx');
      } else if (ext == 'json') {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['body'] != null) {
          _titleController.text = decoded['title'] ?? '';
          content = decoded['body'];
        } else {
          content = const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } else {
        content = await file.readAsString();
      }
      _bodyController.text = content;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Σφάλμα: $e')));
    }
  }

  // ── EXPORT ─────────────────────────────────────────────────────────────────

  Future<void> _exportThisNote() async {
    final choice = await showExportFormatMenu(context: context);
    if (choice == null || !mounted) return;
    setState(() => _isExporting = true);
    try {
      final safeTitle = (_note!.title.isEmpty ? 'note' : _note!.title).replaceAll(RegExp(r'[^\w\-]+'), '_');
      final content = choice.format == ExportFormat.json ? _noteAsJson() : _note!.toMarkdownFile();
      if (choice.format == ExportFormat.qr) {
        if (mounted) showQrExportDialog(context: context, data: content);
        return;
      }
      if (choice.format == ExportFormat.termbin) {
        await _uploadToTermbin();
        return;
      }
      final ext = choice.format == ExportFormat.json ? 'json' : 'md';
      if (!choice.encrypted) {
        final path = await ExportService().exportPlainFile(content: content, filename: '$safeTitle.$ext');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Εξήχθη: $path')));
        return;
      }
      final password = await showExportPasswordDialog(
        context: context,
        hasAppPassphrase: await widget.encryptionService.hasPassphraseProtection(),
      );
      if (password == null) return;
      final path = await ExportService().exportEncryptedZip(
        files: {'$safeTitle.$ext': content}, password: password, outputNamePrefix: 'note_export',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Εξήχθη: $path')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Ανεβάζει τη σημείωση (ως αρχείο markdown με front-matter) στο
  /// termbin.com και επιστρέφει δημόσιο link.
  Future<void> _uploadToTermbin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, el: 'Ανέβασμα στο termbin.com', en: 'Upload to termbin.com')),
        content: Text(tr(
          context,
          el: 'Η σημείωση θα σταλεί ΧΩΡΙΣ κρυπτογράφηση σε δημόσιο pastebin. '
              'Όποιος έχει το link μπορεί να τη διαβάσει. Συνέχεια;',
          en: 'The note will be sent WITHOUT encryption to a public pastebin. '
              'Anyone with the link can read it. Continue?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr(context, el: 'Ανέβασμα', en: 'Upload'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Στέλνουμε ολόκληρο το αρχείο σημείωσης (front-matter + σώμα), ώστε
    // να μπορεί να γίνει ξανά import από την εφαρμογή.
    _note!.title = _titleController.text.trim().isEmpty ? 'Χωρίς τίτλο' : _titleController.text.trim();
    _note!.body = _bodyController.text;
    try {
      final url = await TermbinService.upload(_note!.toMarkdownFile());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr(context, el: 'Ανέβηκε στο termbin', en: 'Uploaded to termbin')),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.of(ctx).pop();
              },
              child: Text(tr(context, el: 'Αντιγραφή link', en: 'Copy link')),
            ),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr(context, el: 'Κλείσιμο', en: 'Close'))),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Αποτυχία ανεβάσματος: $e')),
        );
      }
    }
  }

  String _noteAsJson() => jsonEncode({
    'id': _note!.id, 'title': _note!.title, 'tags': _note!.tags,
    'font': _note!.font, 'createdAt': _note!.createdAt.toIso8601String(),
    'updatedAt': _note!.updatedAt.toIso8601String(), 'body': _note!.body,
  });

  @override
  void dispose() {
    _bodyController.removeListener(_recordHistory);
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  // ── Toolbar button helper ──────────────────────────────────────────────────
  Widget _tb(IconData icon, VoidCallback fn, {String? tip, bool active = false}) => IconButton(
    icon: Icon(icon, size: 20, color: active ? Theme.of(context).colorScheme.primary : null),
    tooltip: tip,
    onPressed: fn,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      // ── AppBar ────────────────────────────────────────────────────────
      // ΣΚΟΠΙΜΑ ελάχιστα κουμπιά εδώ (πάντα χωράνε, σε κάθε μέγεθος
      // οθόνης). Οτιδήποτε δεν χρειάζεται να είναι ΠΑΝΤΑ ορατό (εισαγωγή,
      // εξαγωγή, διαγραφή) πάει στο μενού «⋮». Τα κουμπιά ζουμ/ζωγραφικής
      // της Προβολής μετακόμισαν σε επιπλέον («floating») πάνελ πάνω από
      // το περιεχόμενο — βλ. _buildPreview() — ώστε να μην ξεχειλίζουν
      // ποτέ πάνω στο κουμπί «πίσω».
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _titleController,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: tr(context, el: 'Τίτλος', en: 'Title'),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        actions: [
          // Preview / Edit mode toggle — πάντα ορατό, είναι το πιο συχνό.
          IconButton(
            icon: Icon(_previewMode ? Icons.edit_outlined : Icons.visibility_outlined),
            tooltip: _previewMode
                ? tr(context, el: 'Λειτουργία επεξεργασίας', en: 'Edit mode')
                : tr(context, el: 'Προβολή', en: 'Preview'),
            onPressed: () => setState(() => _previewMode = !_previewMode),
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            tooltip: tr(context, el: 'Αποθήκευση', en: 'Save'),
            onPressed: _isSaving ? null : _save,
          ),
          PopupMenuButton<String>(
            tooltip: tr(context, el: 'Περισσότερα', en: 'More'),
            onSelected: (value) {
              switch (value) {
                case 'import': _importFile(); break;
                case 'export': _exportThisNote(); break;
                case 'delete': _delete(); break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(tr(context, el: 'Εισαγωγή αρχείου', en: 'Import file')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                enabled: !_isExporting,
                child: ListTile(
                  leading: _isExporting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share_outlined),
                  title: Text(tr(context, el: 'Εξαγωγή σημείωσης', en: 'Export note')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.existingNoteId != null)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
                    title: Text(
                      tr(context, el: 'Διαγραφή', en: 'Delete'),
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tags ────────────────────────────────────────────────────────
          if (_note!.tags.isNotEmpty || !_previewMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final tag in _note!.tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: _previewMode ? null : () => setState(() => _note!.tags = _note!.tags.where((t) => t != tag).toList()),
                    ),
                  if (!_previewMode)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Κατηγορία'),
                      onPressed: () async {
                        final tag = await pickOrCreateCategory(context: context, database: widget.database, kind: 'note');
                        if (tag != null && !_note!.tags.contains(tag)) setState(() => _note!.tags = [..._note!.tags, tag]);
                      },
                    ),
                ],
              ),
            ),

          // ── Formatting Toolbar (μόνο στο edit mode) ──────────────────
          if (!_previewMode) ...[
            const Divider(height: 1),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  // Heading dropdown
                  PopupMenuButton<int>(
                    tooltip: 'Επικεφαλίδα',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ]),
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 0, child: Text('Κανονικό')),
                      const PopupMenuItem(value: 1, child: Text('H1 — Τίτλος', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      const PopupMenuItem(value: 2, child: Text('H2 — Υπότιτλος', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      const PopupMenuItem(value: 3, child: Text('H3 — Μικρός', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                    ],
                    onSelected: (level) {
                      if (level == 0) { for (var l = 1; l <= 3; l++) _togglePrefix('${'#' * l} '); }
                      else _togglePrefix('${'#' * level} ');
                    },
                  ),
                  _tb(Icons.format_bold, () => _toggleWrap('**', '**'), tip: tr(context, el: 'Έντονο', en: 'Bold'), active: _selectionWrapped('**', '**')),
                  _tb(Icons.format_italic, () => _toggleWrap('*', '*'), tip: tr(context, el: 'Πλάγιο', en: 'Italic'), active: _selectionWrapped('*', '*')),
                  _tb(Icons.format_underlined, () => _toggleWrap('<u>', '</u>'), tip: tr(context, el: 'Υπογράμμιση', en: 'Underline'), active: _selectionWrapped('<u>', '</u>')),
                  _tb(Icons.format_strikethrough, () => _toggleWrap('~~', '~~'), tip: tr(context, el: 'Διαγραφή', en: 'Strikethrough'), active: _selectionWrapped('~~', '~~')),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                  _tb(Icons.format_list_bulleted, () => _togglePrefix('- '), tip: tr(context, el: 'Λίστα', en: 'Bullet list')),
                  _tb(Icons.format_list_numbered, () => _togglePrefix('1. '), tip: tr(context, el: 'Αριθμημένη λίστα', en: 'Numbered list')),
                  _tb(Icons.check_box_outlined, () => _togglePrefix('- [ ] '), tip: tr(context, el: 'Λίστα εργασιών', en: 'Task list')),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                  _tb(Icons.code, () => _toggleWrap('`', '`'), tip: tr(context, el: 'Inline κώδικας', en: 'Inline code'), active: _selectionWrapped('`', '`')),
                  _tb(Icons.data_object, () => _toggleWrap('\n```\n', '\n```\n'), tip: tr(context, el: 'Block κώδικα', en: 'Code block')),
                  _tb(Icons.format_quote, () => _togglePrefix('> '), tip: tr(context, el: 'Παράθεση', en: 'Quote')),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                  _tb(Icons.image_outlined, _insertImage, tip: tr(context, el: 'Εικόνα', en: 'Image')),
                  _tb(Icons.draw_outlined, _openDrawing, tip: tr(context, el: 'Σχέδιο', en: 'Drawing')),
                  _tb(Icons.emoji_emotions_outlined, _insertClipArt, tip: tr(context, el: 'Clip art', en: 'Clip art')),
                  _tb(Icons.layers_outlined, _drawOverEverything, tip: tr(context, el: 'Ζωγραφική πάνω σε όλα (πάνω layer)', en: 'Draw over everything (top layer)')),
                  if (_overlayBytes != null)
                    _tb(Icons.layers_clear_outlined, _clearOverlay, tip: tr(context, el: 'Διαγραφή επιπέδου ζωγραφικής', en: 'Delete drawing layer')),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                  // Γραμματοσειρά σημείωσης
                  InkWell(
                    onTap: _pickFont,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.font_download_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(_note!.font,
                            style: NoteFonts.style(_note!.font, const TextStyle(fontSize: 13))),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                  _tb(Icons.undo, _undo, tip: tr(context, el: 'Αναίρεση', en: 'Undo'), active: _historyIndex > 0),
                  _tb(Icons.redo, _redo, tip: tr(context, el: 'Επαναφορά', en: 'Redo'), active: _historyIndex < _history.length - 1),
                  const SizedBox(width: 8),
                ]),
              ),
            ),
          ],
          const Divider(height: 1),

          // ── Περιεχόμενο ────────────────────────────────────────────────
          Expanded(
            child: _previewMode ? _buildPreview() : _buildEditor(),
          ),
        ],
      ),
    );
  }

  /// Raw markdown editor
  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _bodyController,
        focusNode: _bodyFocusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: NoteFonts.style(
          _note!.font,
          const TextStyle(fontSize: 15, height: 1.5),
        ),
        decoration: const InputDecoration(
          hintText: '# Γράψε σε markdown...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Ζουμ γύρω από το κέντρο της οθόνης (διατηρεί το σημείο εστίασης).
  void _applyZoom(double factor) {
    final current = _zoomController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minZoom, _maxZoom);
    _setZoom(target);
  }

  void _setZoom(double target) {
    final current = _zoomController.value.getMaxScaleOnAxis();
    if ((target - current).abs() < 0.001) return;
    // Κρατάμε το κέντρο του viewport σταθερό όσο αλλάζει η κλίμακα.
    final size = _previewViewportSize;
    final focal = Offset(size.width / 2, size.height / 2);
    final translation = _zoomController.value.getTranslation();
    final scene = (focal - Offset(translation.x, translation.y)) / current;
    final newTranslation = focal - scene * target;
    _zoomController.value = Matrix4.identity()
      ..translate(newTranslation.dx, newTranslation.dy)
      ..scale(target);
    setState(() => _zoomLevel = target);
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    setState(() => _zoomLevel = 1.0);
  }

  /// Διπλό πάτημα: εναλλαγή 100% ↔ 250% στο σημείο που πάτησες.
  void _handleDoubleTap(TapDownDetails details) {
    if (_zoomLevel > 1.05) {
      _resetZoom();
      return;
    }
    const target = 2.5;
    final focal = details.localPosition;
    _zoomController.value = Matrix4.identity()
      ..translate(focal.dx - focal.dx * target, focal.dy - focal.dy * target)
      ..scale(target);
    setState(() => _zoomLevel = target);
  }

  /// Rendered markdown preview — υποστηρίζει ζουμ (pinch/κουμπιά), local
  /// images (file://) με προσαρμοσμένο μέγεθος ("w=NN" attribute) και tap
  /// πάνω σε μια εικόνα για να αλλάξεις εύκολα το μέγεθός της.
  Widget _buildPreview() {
    final text = _bodyController.text;
    if (text.trim().isEmpty) {
      return Center(child: Text(tr(context, el: '(κενή σημείωση)', en: '(empty note)'), style: const TextStyle(color: Colors.grey)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _previewViewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final availableWidth = constraints.maxWidth - 32; // πλάτος μείον padding
        return Stack(
          children: [
            _buildPreviewInteractiveArea(availableWidth),
            // ── Floating πάνελ ζουμ / ζωγραφικής ────────────────────────
            // Ζήτημα που διορθώθηκε: αυτά τα κουμπιά ήταν πριν στο AppBar
            // και ξεχείλιζαν πάνω στο κουμπί «πίσω» σε μικρές οθόνες. Εδώ
            // επιπλέουν πάνω από το περιεχόμενο, σε κατακόρυφη στήλη,
            // οπότε χωράνε πάντα ανεξαρτήτως πλάτους οθόνης.
            Positioned(
              right: 8,
              bottom: 8,
              child: _buildFloatingPreviewPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingPreviewPanel() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: tr(context, el: 'Μεγέθυνση', en: 'Zoom in'),
            onPressed: () => _applyZoom(1.25),
          ),
          InkWell(
            onTap: _resetZoom,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${(_zoomLevel * 100).round()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: tr(context, el: 'Σμίκρυνση', en: 'Zoom out'),
            onPressed: () => _applyZoom(1 / 1.25),
          ),
          if (_zoomLevel != 1.0)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: tr(context, el: 'Επαναφορά ζουμ', en: 'Reset zoom'),
              onPressed: _resetZoom,
            ),
          const Divider(height: 1),
          if (_overlayBytes != null)
            IconButton(
              icon: Icon(_overlayVisible ? Icons.gesture : Icons.gesture_outlined,
                  color: _overlayVisible ? Theme.of(context).colorScheme.primary : null),
              tooltip: _overlayVisible
                  ? tr(context, el: 'Απόκρυψη ζωγραφιάς', en: 'Hide drawing')
                  : tr(context, el: 'Εμφάνιση ζωγραφιάς', en: 'Show drawing'),
              onPressed: () => setState(() => _overlayVisible = !_overlayVisible),
            ),
          IconButton(
            icon: _isFlatteningDrawing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.layers_outlined),
            tooltip: tr(context, el: 'Ζωγραφική πάνω σε όλα', en: 'Draw over everything'),
            onPressed: _isFlatteningDrawing ? null : _drawOverEverything,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewInteractiveArea(double availableWidth) {
    return GestureDetector(
          onDoubleTapDown: (d) => _lastDoubleTapDetails = d,
          onDoubleTap: () {
            if (_lastDoubleTapDetails != null) _handleDoubleTap(_lastDoubleTapDetails!);
          },
          child: InteractiveViewer(
          transformationController: _zoomController,
          minScale: _minZoom,
          maxScale: _maxZoom,
          // Επιτρέπουμε λίγο «αέρα» γύρω-γύρω ώστε να μπορείς να σύρεις
          // τη σελίδα όταν είσαι ζουμαρισμένος.
          boundaryMargin: const EdgeInsets.all(200),
          panEnabled: true,
          scaleEnabled: true,
          onInteractionEnd: (_) {
            final z = _zoomController.value.getMaxScaleOnAxis();
            if ((z - _zoomLevel).abs() > 0.01) setState(() => _zoomLevel = z);
          },
          child: SizedBox(
            width: constraints.maxWidth,
            child: SingleChildScrollView(
            child: RepaintBoundary(
              key: _previewRepaintKey,
              child: Stack(
                children: [
                  Container(
                // Άσπρο/σκούρο φόντο ώστε το snapshot της "ζωγραφικής πάνω σε
                // όλα" να μην είναι διάφανο.
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: text,
                  selectable: true,
                  extensionSet: md.ExtensionSet.gitHubFlavored,
                  imageBuilder: (uri, title, alt) {
                    final uriStr = uri.toString();
                    final widthPercent = (title != null && title.startsWith('w='))
                        ? int.tryParse(title.substring(2)) ?? 60
                        : 60;
                    final targetWidth = (availableWidth * widthPercent / 100).clamp(24.0, availableWidth);
                    Widget img;
                    String? localPath;
                    if (uriStr.startsWith('/') || uriStr.startsWith('file://')) {
                      localPath = uriStr.startsWith('file://') ? uriStr.substring(7) : uriStr;
                      final file = File(localPath);
                      if (file.existsSync()) {
                        img = Image.file(file, width: targetWidth, fit: BoxFit.contain);
                      } else {
                        img = const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey);
                      }
                    } else {
                      img = Image.network(
                        uriStr,
                        width: targetWidth,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                      );
                    }
                    if (localPath == null) return img;
                    final path = localPath;
                    return GestureDetector(
                      onTap: () => _resizeExistingImage(path),
                      child: img,
                    );
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    // Η γραμματοσειρά της σημείωσης εφαρμόζεται σε ΟΛΟ το
                    // rendered markdown (τίτλοι, παράγραφοι, λίστες...).
                    Theme.of(context).copyWith(
                      textTheme: NoteFonts.textTheme(_note!.font, Theme.of(context).textTheme),
                    ),
                  ).copyWith(
                    p: NoteFonts.style(_note!.font,
                        Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                    h1: NoteFonts.style(_note!.font,
                        Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    h2: NoteFonts.style(_note!.font,
                        Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    h3: NoteFonts.style(_note!.font,
                        Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    code: TextStyle(fontFamily: 'monospace', backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                    codeblockDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
                    ),
                  ),
                ),
              ),

                  // ── OVERLAY LAYER (ζωγραφική) ─────────────────────────
                  // Μπαίνει ΤΕΛΕΥΤΑΙΟ στο Stack, άρα αποδίδεται ΠΑΝΩ από
                  // το κείμενο και τα πολυμέσα. Το IgnorePointer αφήνει
                  // την επιλογή κειμένου / το tap στις εικόνες να δουλεύουν
                  // κανονικά από κάτω.
                  if (_overlayBytes != null && _overlayVisible)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Image.memory(
                          _overlayBytes!,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
          ),
        );
  }
}
