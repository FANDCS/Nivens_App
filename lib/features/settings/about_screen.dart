import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'org_info_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'android_creator@inbox.vg',
      query: 'subject=Nivens - Επικοινωνία',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Δεν βρέθηκε εφαρμογή email στη συσκευή.')),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Δεν ήταν δυνατό το άνοιγμα: $url')),
      );
    }
  }

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
              child: Icon(
                Icons.note_outlined,
                size: 44,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Nivens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Έκδοση 0.1.0', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Σημειώσεις σε markdown με πολυμέσα, ζωγραφική, κρυπτογράφηση και '
            'συγχρονισμό μεταξύ συσκευών (Android/desktop) — μαζί με ένα '
            'ξεχωριστό ημερολόγιο καθημερινών σχολίων. Μέρος μιας σουίτας '
            'εφαρμογών με κοινό, plugable σύστημα συγχρονισμού.',
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Δεν συλλέγουμε στατιστικά δεδομένα χρήσης.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Οργανισμός & Συντελεστές'),
            subtitle: const Text('FANDCS · Ομάδα'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrgInfoScreen()),
            ),
          ),
          const Divider(height: 32),

          const ListTile(
            leading: Icon(Icons.code_outlined),
            title: Text('Χτισμένο με Flutter'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Άδειες χρήσης βιβλιοθηκών'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Nivens',
              applicationVersion: '0.1.0',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Πολιτική Απορρήτου & Όροι Χρήσης'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(
              context,
              'https://raw.githubusercontent.com/FANDCS/main/refs/heads/main/Privacy_Policy_and_Terms_of_Use.md',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Επικοινωνία'),
            subtitle: const Text('android_creator@inbox.vg'),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEmail(context),
          ),
        ],
      ),
    );
  }
}
