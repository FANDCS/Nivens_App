import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/storage/app_database.dart';
import 'trash_service.dart';

/// Κάδος σημειώσεων: λίστα διαγραμμένων, επαναφορά, οριστική διαγραφή,
/// «Άδειασμα κάδου». Οι εγγραφές > 35 ημερών διαγράφονται αυτόματα.
class TrashScreen extends StatefulWidget {
  final AppDatabase database;
  const TrashScreen({super.key, required this.database});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late final TrashService _service = TrashService(widget.database);

  @override
  void initState() {
    super.initState();
    _service.purgeExpired();
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: _service.watchTrashed(),
      builder: (context, snap) {
        final items = snap.data ?? const <Note>[];
        return Scaffold(
          appBar: AppBar(
            title: Text(tr(context, el: 'Κάδος', en: 'Trash')),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: tr(context, el: 'Άδειασμα κάδου', en: 'Empty trash'),
                  onPressed: () async {
                    final ok = await _confirm(
                      tr(context, el: 'Άδειασμα κάδου', en: 'Empty trash'),
                      tr(context,
                          el: 'Όλα τα στοιχεία θα διαγραφούν οριστικά. Δεν γίνεται αναίρεση.',
                          en: 'All items will be permanently deleted. This cannot be undone.'),
                      tr(context, el: 'Διαγραφή όλων', en: 'Delete all'),
                    );
                    if (ok) await _service.emptyTrash();
                  },
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Text(
                    tr(context, el: 'Ο κάδος είναι άδειος', en: 'Trash is empty'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr(context,
                              el: 'Τα στοιχεία διαγράφονται οριστικά αυτόματα μετά από ${TrashService.retentionDays} μέρες στον κάδο.',
                              en: 'Items are permanently deleted automatically after ${TrashService.retentionDays} days in the trash.'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    final n = items[i - 1];
                    final left = TrashService.daysLeft(n.updatedAt);
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(n.title.isEmpty ? '—' : n.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(tr(context,
                          el: 'Διαγράφεται σε $left ημ.',
                          en: 'Deleted in $left d')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_from_trash_outlined),
                            tooltip: tr(context, el: 'Επαναφορά', en: 'Restore'),
                            onPressed: () async {
                              await _service.restore(n.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(tr(context,
                                      el: 'Η σημείωση επανήλθε',
                                      en: 'Note restored'))));
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_forever_outlined,
                                color: Theme.of(context).colorScheme.error),
                            tooltip: tr(context,
                                el: 'Οριστική διαγραφή', en: 'Delete permanently'),
                            onPressed: () async {
                              final ok = await _confirm(
                                tr(context,
                                    el: 'Οριστική διαγραφή', en: 'Delete permanently'),
                                tr(context,
                                    el: 'Η σημείωση θα διαγραφεί οριστικά. Δεν γίνεται αναίρεση.',
                                    en: 'The note will be permanently deleted. This cannot be undone.'),
                                tr(context, el: 'Διαγραφή', en: 'Delete'),
                              );
                              if (ok) await _service.deleteForever(n.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
