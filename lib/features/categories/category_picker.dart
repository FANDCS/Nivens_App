import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/storage/app_database.dart';

/// Ανοίγει dialog με τις υπάρχουσες κατηγορίες (kind: 'note' ή 'daily') +
/// δυνατότητα να φτιάξει ο χρήστης καινούρια.
Future<String?> pickOrCreateCategory({
  required BuildContext context,
  required AppDatabase database,
  required String kind,
}) async {
  final newCategoryController = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StreamBuilder(
          stream: (database.select(database.categories)
                ..where((c) => c.kind.equals(kind)))
              .watch(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Κατηγορίες', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in categories)
                      InputChip(
                        label: Text(c.name),
                        onPressed: () => Navigator.of(context).pop(c.name),
                        onDeleted: () async {
                          await (database.delete(database.categories)
                                ..where((row) => row.id.equals(c.id)))
                              .go();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newCategoryController,
                        decoration: const InputDecoration(
                          hintText: 'Νέα κατηγορία...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final name = newCategoryController.text.trim();
                        if (name.isEmpty) return;
                        await database.into(database.categories).insert(
                              CategoriesCompanion.insert(
                                id: const Uuid().v4(),
                                name: name,
                                kind: kind,
                              ),
                            );
                        if (context.mounted) Navigator.of(context).pop(name);
                      },
                      child: const Text('Προσθήκη'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
