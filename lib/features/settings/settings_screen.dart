import 'package:flutter/material.dart';
import '../../core/encryption/encryption_service.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final EncryptionService encryptionService;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final Locale? currentLocale;

  const SettingsScreen({
    super.key,
    required this.encryptionService,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hasPassphrase;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final has = await widget.encryptionService.hasPassphraseProtection();
    if (mounted) setState(() => _hasPassphrase = has);
  }

  Future<void> _setPassphraseDialog() async {
    final c1 = TextEditingController(), c2 = TextEditingController();
    String? err;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ορισμός κωδικού'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: c1, obscureText: true, decoration: const InputDecoration(labelText: 'Νέος κωδικός')),
            const SizedBox(height: 8),
            TextField(controller: c2, obscureText: true, decoration: const InputDecoration(labelText: 'Επιβεβαίωση')),
            if (err != null) ...[const SizedBox(height: 8), Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Άκυρο')),
            FilledButton(
              onPressed: () {
                if (c1.text.length < 8) { setS(() => err = 'Τουλάχιστον 8 χαρακτήρες.'); return; }
                if (c1.text != c2.text) { setS(() => err = 'Δεν ταιριάζουν.'); return; }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Αποθήκευση'),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      await widget.encryptionService.initializeFromPassphrase(c1.text);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ο κωδικός ορίστηκε.')));
    }
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις')),
      body: _hasPassphrase == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              // ── Εμφάνιση ──────────────────────────────────────────────────
              _header('Εμφάνιση'),
              RadioListTile<ThemeMode>(title: const Text('Σύστημα'), value: ThemeMode.system, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              RadioListTile<ThemeMode>(title: const Text('Φωτεινό'), value: ThemeMode.light, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              RadioListTile<ThemeMode>(title: const Text('Σκοτεινό'), value: ThemeMode.dark, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              const Divider(height: 32),

              // ── Γλώσσα ────────────────────────────────────────────────────
              _header('Γλώσσα'),
              RadioListTile<Locale?>(title: const Text('Σύστημα'), value: null, groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              RadioListTile<Locale?>(title: const Text('Ελληνικά'), value: const Locale('el'), groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              RadioListTile<Locale?>(title: const Text('English'), value: const Locale('en'), groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              const Divider(height: 32),

              // ── Ασφάλεια ──────────────────────────────────────────────────
              _header('Ασφάλεια'),
              ListTile(
                leading: Icon(_hasPassphrase! ? Icons.lock : Icons.lock_open),
                title: const Text('Προστασία με κωδικό'),
                subtitle: Text(_hasPassphrase!
                    ? 'Ενεργή — οι σημειώσεις προστατεύονται με τον κωδικό σου.'
                    : 'Ανενεργή — αυτόματο κλειδί συσκευής.'),
                trailing: _hasPassphrase! ? null : FilledButton(onPressed: _setPassphraseDialog, child: const Text('Ορισμός')),
              ),
              const Divider(height: 32),

              // ── Σχετικά ───────────────────────────────────────────────────
              _header('Σχετικά'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Σχετικά με την εφαρμογή'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
              const SizedBox(height: 32),
            ]),
    );
  }
}
