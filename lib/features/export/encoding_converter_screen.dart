import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/i18n.dart';
import '../../core/storage/nivens_folder.dart';
import '../../core/text_encoding.dart';

/// Εργαλείο: άλλαξε την κωδικοποίηση ενός αρχείου κειμένου — π.χ. ένα παλιό
/// .txt/.csv σε Windows-1253 (ελληνικά) που θες σε UTF-8, ή το αντίστροφο
/// για συμβατότητα με κάποιο παλιό πρόγραμμα. Δεν αγγίζει τα δεδομένα της
/// εφαρμογής (σημειώσεις/καθημερινά) — δουλεύει σε ΟΠΟΙΟΔΗΠΟΤΕ αρχείο
/// κειμένου που διαλέξεις, ανεξάρτητα από το Nivens.
class EncodingConverterScreen extends StatefulWidget {
  const EncodingConverterScreen({super.key});

  @override
  State<EncodingConverterScreen> createState() => _EncodingConverterScreenState();
}

class _EncodingConverterScreenState extends State<EncodingConverterScreen> {
  File? _file;
  Uint8List? _bytes;
  TextEncoding _source = TextEncoding.utf8Enc;
  TextEncoding _target = TextEncoding.utf8Enc;
  String? _error;
  bool _saving = false;
  String? _savedPath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final guessed = TextCodecs.detect(bytes);
    setState(() {
      _file = file;
      _bytes = bytes;
      _source = guessed;
      _target = TextEncoding.utf8Enc;
      _error = null;
      _savedPath = null;
    });
  }

  String get _preview {
    final bytes = _bytes;
    if (bytes == null) return '';
    try {
      final text = TextCodecs.decode(bytes, _source);
      return text.length > 4000 ? '${text.substring(0, 4000)}…' : text;
    } catch (e) {
      return '';
    }
  }

  Future<void> _convertAndSave() async {
    final file = _file;
    final bytes = _bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _savedPath = null;
    });
    try {
      final text = TextCodecs.decode(bytes, _source);
      final outBytes = TextCodecs.encode(text, _target);
      final dir = await NivensFolder.sub('exports');
      final baseName = p.basenameWithoutExtension(file.path);
      final ext = p.extension(file.path).isEmpty ? '.txt' : p.extension(file.path);
      final outPath = p.join(dir.path, '${baseName}_${_target.id}$ext');
      await File(outPath).writeAsBytes(outBytes);
      if (mounted) setState(() => _savedPath = outPath);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _encodingDropdown({
    required String label,
    required TextEncoding value,
    required ValueChanged<TextEncoding?> onChanged,
  }) {
    return DropdownButtonFormField<TextEncoding>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final e in TextEncoding.all) DropdownMenuItem(value: e, child: Text(e.label)),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Μετατροπή κωδικοποίησης', en: 'Encoding converter'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr(context,
                el: 'Διάβασε ένα αρχείο κειμένου με μία κωδικοποίηση και αποθήκευσέ το με άλλη — π.χ. ένα παλιό .txt σε Windows-1253 προς UTF-8.',
                en: 'Read a text file in one encoding and save it in another — e.g. an old Windows-1253 .txt into UTF-8.'),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(tr(context, el: 'Επιλογή αρχείου', en: 'Choose file')),
          ),
          if (_file != null) ...[
            const SizedBox(height: 8),
            Text(p.basename(_file!.path), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _encodingDropdown(
              label: tr(context, el: 'Πηγή (ανιχνεύθηκε αυτόματα, άλλαξέ την αν το κείμενο φαίνεται λάθος)', en: 'Source (auto-detected — change it if the text below looks wrong)'),
              value: _source,
              onChanged: (v) => setState(() => _source = v ?? _source),
            ),
            const SizedBox(height: 12),
            _encodingDropdown(
              label: tr(context, el: 'Στόχος', en: 'Target'),
              value: _target,
              onChanged: (v) => setState(() => _target = v ?? _target),
            ),
            const SizedBox(height: 16),
            Text(tr(context, el: 'Προεπισκόπηση (με την επιλεγμένη πηγή):', en: 'Preview (using the selected source):'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 240),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: SelectableText(_preview)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _convertAndSave,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(tr(context, el: 'Μετατροπή & Αποθήκευση', en: 'Convert & Save')),
            ),
            if (_savedPath != null) ...[
              const SizedBox(height: 12),
              Text('${tr(context, el: 'Αποθηκεύτηκε', en: 'Saved')}: $_savedPath'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ],
      ),
    );
  }
}
