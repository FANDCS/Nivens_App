import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';

/// Οθόνη «Οργανισμός & συντελεστές» — ίδια εμφάνιση/χρώματα με την
/// OrgInfoScreen της Callen: brand χρώμα για FANDCS/GitHub/Android Creator,
/// μωβ (Colors.purple) για τον designer Alex632gr, γκρι για τα δευτερεύοντα.
///
/// Το [brand] είναι το AppColors.brand της Callen. Αν το Nivens έχει δικό του
/// αντίστοιχο χρώμα πέρασέ το εδώ (π.χ. brand: AppColors.brand)· αλλιώς
/// χρησιμοποιείται το primary χρώμα του θέματος.
class CreditsScreen extends StatelessWidget {
  final Color? brand;
  const CreditsScreen({super.key, this.brand});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${tr(context, el: 'Δεν ήταν δυνατό το άνοιγμα', en: 'Could not open')}: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = brand ?? Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr(context,
              el: 'Οργανισμός & συντελεστές', en: 'Organization & contributors'))),
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
                  errorBuilder: (_, __, ___) => Icon(Icons.groups, size: 36, color: c),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('FANDCS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: c.withValues(alpha: 0.08),
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
                        color: c.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.code, size: 20, color: c),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GitHub',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('github.com/FANDCS',
                              style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 18, color: c),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 40),
          Text(tr(context, el: 'ΣΥΝΤΕΛΕΣΤΕΣ', en: 'CONTRIBUTORS'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.laptop_mac, size: 22, color: c),
            ),
            title: const Text('Android Creator'),
            subtitle: Text(tr(context, el: 'Προγραμματιστής', en: 'Developer')),
            contentPadding: EdgeInsets.zero,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, 'https://github.com/AndroidCreator5'),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette_outlined, size: 22, color: Colors.purple),
            ),
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
