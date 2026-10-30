import 'package:flutter/material.dart';
import '../../core/dailies_setting.dart';
import '../../core/i18n.dart';

/// Διακόπτης για τις Ρυθμίσεις: ενεργοποίηση/απενεργοποίηση των Καθημερινών.
class DailiesToggleTile extends StatelessWidget {
  const DailiesToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DailiesSetting.enabled,
      builder: (context, on, _) => SwitchListTile(
        secondary: const Icon(Icons.today_outlined),
        title: Text(tr(context, el: 'Καθημερινά', en: 'Dailies')),
        subtitle: Text(tr(context,
            el: 'Όταν είναι ανενεργά κρύβονται, αλλά τα δεδομένα σου δεν διαγράφονται.',
            en: 'When off they are hidden, but your data is not deleted.')),
        value: on,
        onChanged: DailiesSetting.set,
      ),
    );
  }
}
