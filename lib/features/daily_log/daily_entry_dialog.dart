import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../categories/category_picker.dart';

Future<void> showAddDailyEntryDialog({
  required BuildContext context,
  required AppDatabase database,
  required EncryptionService encryptionService,
  DailyEntry? existing,
}) async {
  final textController = TextEditingController();
  String? selectedTag = existing?.tag;
  int weight = existing?.weight ?? 1;

  if (existing != null) {
    textController.text = await encryptionService.decryptText(existing.encryptedText);
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Νέα καταχώρηση' : 'Επεξεργασία'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Τι σε απασχόλησε σήμερα;',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (selectedTag != null)
                    InputChip(
                      label: Text(selectedTag!),
                      onDeleted: () => setDialogState(() => selectedTag = null),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Κατηγορία'),
                    onPressed: () async {
                      final tag = await pickOrCreateCategory(
                        context: context,
                        database: database,
                        kind: 'daily',
                      );
                      if (tag != null) setDialogState(() => selectedTag = tag);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Βαρύτητα: '),
                  Expanded(
                    child: Slider(
                      value: weight.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: weight.toString(),
                      onChanged: (v) => setDialogState(() => weight = v.round()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Άκυρο'),
          ),
          FilledButton(
            onPressed: textController.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(true),
            child: Text(existing == null ? 'Προσθήκη' : 'Αποθήκευση'),
          ),
        ],
      ),
    ),
  );

  if (result == true && textController.text.trim().isNotEmpty) {
    final encryptedText = await encryptionService.encryptText(textController.text.trim());
    if (existing == null) {
      await database.into(database.dailyEntries).insert(
            DailyEntriesCompanion.insert(
              id: const Uuid().v4(),
              timestamp: DateTime.now().toUtc(),
              encryptedText: encryptedText,
              tag: Value(selectedTag),
              weight: Value(weight),
            ),
          );
    } else {
      await (database.update(database.dailyEntries)..where((e) => e.id.equals(existing.id)))
          .write(DailyEntriesCompanion(
        encryptedText: Value(encryptedText),
        tag: Value(selectedTag),
        weight: Value(weight),
        isSynced: const Value(false),
      ));
    }
  }
}

Future<void> deleteDailyEntry({
  required AppDatabase database,
  required String id,
}) async {
  await (database.delete(database.dailyEntries)..where((e) => e.id.equals(id))).go();
}
