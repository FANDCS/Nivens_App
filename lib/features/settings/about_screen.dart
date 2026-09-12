import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Σχετικά')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.note_outlined,
                  size: 44, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Notes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Έκδοση 0.1.0', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Σημειώσεις σε markdown με πολυμέσα, ζωγραφική, κρυπτογράφηση '
            'και συγχρονισμό μεταξύ συσκευών — μαζί με ένα ξεχωριστό '
            'ημερολόγιο καθημερινών σχολίων.',
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.code_outlined),
            title: Text('Φτιαγμένο με Flutter'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Άδειες χρήσης'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Notes',
              applicationVersion: '0.1.0',
            ),
          ),
        ],
      ),
    );
  }
}
