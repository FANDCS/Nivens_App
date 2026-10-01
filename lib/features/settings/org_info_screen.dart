import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';

class OrgInfoScreen extends StatelessWidget {
  const OrgInfoScreen({super.key});

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
    final brand = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Οργανισμός & Συντελεστές', en: 'Organization & Contributors'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/icons/fandcs_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.groups_outlined, size: 28, color: brand),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'FANDCS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr(context,
              el: 'Η FANDCS είναι μια ανεξάρτητη, open-source ομάδα ανάπτυξης που '
                  'δημιουργεί ψηφιακές εμπειρίες από το 2022. Φτιάχνουμε 100% δωρεάν '
                  'εφαρμογές και ιστότοπους με αυστηρή φιλοσοφία privacy-first: καμία '
                  'συλλογή δεδομένων, κανένα tracker, καμία διαφήμιση. Η αποστολή μας '
                  'είναι να κρατήσουμε τον ψηφιακό κόσμο ανοιχτό, διαφανή και '
                  'προσβάσιμο σε όλους.',
              en: 'FANDCS is an independent, open-source development team crafting '
                  'digital experiences since 2022. We build 100% free apps and '
                  'websites with a strict privacy-first approach: no data collection, '
                  'no trackers, and no advertisements. Our mission is to keep the '
                  'digital world open, transparent, and accessible to everyone.')),
          const SizedBox(height: 16),

          Material(
            color: brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openUrl(context, 'https://github.com/FANDCS'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: brand.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.code, size: 20, color: brand),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'GitHub',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'github.com/FANDCS',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 18, color: brand),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 40),

          Text(
            tr(context, el: 'ΣΥΝΤΕΛΕΣΤΕΣ', en: 'CONTRIBUTORS'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Android Creator'),
            subtitle: Text(tr(context, el: 'Προγραμματιστής', en: 'Developer')),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, 'https://github.com/AndroidCreator5'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Alex632gr'),
            subtitle: Text(tr(context, el: 'Σχεδιαστής', en: 'Designer')),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, 'https://www.instagram.com/alex632gr_'),
          ),
        ],
      ),
    );
  }
}
