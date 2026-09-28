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
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/icons/fandcs_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.groups_outlined, color: brand),
                  ),
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
              el: 'Ο οργανισμός/ομάδα πίσω από την ανάπτυξη και τον σχεδιασμό αυτής '
                  'της εφαρμογής και της υπόλοιπης σουίτας εφαρμογών.',
              en: 'The organization/team behind the development and design of this '
                  'app and the rest of the app suite.')),
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
