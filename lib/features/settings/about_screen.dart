import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';
import 'org_info_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'android_creator@inbox.vg',
      query: 'subject=Nivens - Επικοινωνία / Contact',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, el: 'Δεν βρέθηκε εφαρμογή email στη συσκευή.', en: 'No email app found on this device.'))),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, el: 'Δεν ήταν δυνατό το άνοιγμα', en: 'Could not open')}: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Σχετικά', en: 'About'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              // Βάλε το πραγματικό εικονίδιο της εφαρμογής (π.χ. export από
              // τον launcher icon σου) σε assets/icons/nivens_icon.png — θα
              // εμφανιστεί αυτόματα εδώ. Μέχρι τότε δείχνει ένα placeholder.
              child: Image.asset(
                'assets/icons/nivens_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.note_outlined,
                  size: 44,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Nivens', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                tr(context, el: 'Έκδοση 0.1.0', en: 'Version 0.1.0'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(tr(context,
              el: 'Σημειώσεις σε markdown με πολυμέσα, ζωγραφική, κρυπτογράφηση και '
                  'συγχρονισμό μεταξύ συσκευών (Android/desktop) — μαζί με ένα '
                  'ξεχωριστό ημερολόγιο καθημερινών σχολίων. Μέρος μιας σουίτας '
                  'εφαρμογών με κοινό, plugable σύστημα συγχρονισμού.',
              en: 'Markdown notes with media, drawing, encryption and cross-device '
                  '(Android/desktop) sync — plus a separate daily-log journal. Part of '
                  'a suite of apps sharing a common, pluggable sync system.')),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(context, el: 'Δεν συλλέγουμε στατιστικά δεδομένα χρήσης.', en: "We don't collect usage analytics."),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(tr(context, el: 'Οργανισμός & Συντελεστές', en: 'Organization & Contributors')),
            subtitle: Text(tr(context, el: 'FANDCS · Ομάδα', en: 'FANDCS · Team')),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrgInfoScreen()),
            ),
          ),
          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: Text(tr(context, el: 'Χτισμένο με Flutter', en: 'Built with Flutter')),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(tr(context, el: 'Άδειες χρήσης βιβλιοθηκών', en: 'Open-source licenses')),
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
            title: Text(tr(context, el: 'Πολιτική Απορρήτου & Όροι Χρήσης', en: 'Privacy Policy & Terms of Use')),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(
              context,
              'https://raw.githubusercontent.com/FANDCS/main/refs/heads/main/Privacy_Policy_and_Terms_of_Use.md',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(tr(context, el: 'Επικοινωνία', en: 'Contact')),
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
