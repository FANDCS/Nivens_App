import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/storage/app_database.dart';
import 'trash_screen.dart';

/// Κουμπί «Κάδος» για το AppBar της αρχικής οθόνης.
class TrashButton extends StatelessWidget {
  final AppDatabase database;
  const TrashButton({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: tr(context, el: 'Κάδος', en: 'Trash'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrashScreen(database: database)),
      ),
    );
  }
}
