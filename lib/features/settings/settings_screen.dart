import 'package:flutter/material.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/sync/sync_backend.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_settings_store.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final EncryptionService encryptionService;
  final AppDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final Locale? currentLocale;

  const SettingsScreen({
    super.key,
    required this.encryptionService,
    required this.database,
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

  SyncSettingsStore? _syncStore;
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _deviceIdController;
  late final TextEditingController _encryptionPasswordController;
  bool _syncEnabled = false;
  String _syncBackend = 'supabase';
  bool _syncing = false;
  bool _syncSettingsSaved = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _deviceIdController = TextEditingController();
    _encryptionPasswordController = TextEditingController();
    _load();
    _loadSyncSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _deviceIdController.dispose();
    _encryptionPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final has = await widget.encryptionService.hasPassphraseProtection();
    if (mounted) setState(() => _hasPassphrase = has);
  }

  Future<void> _loadSyncSettings() async {
    final store = await SyncSettingsStore.load();
    await store.ensureSyncDeviceId();
    if (!mounted) return;
    setState(() {
      _syncStore = store;
      _urlController.text = store.syncServerUrl;
      _apiKeyController.text = store.syncApiKey;
      _deviceIdController.text = store.syncDeviceId;
      _encryptionPasswordController.text = store.syncEncryptionPassword;
      _syncEnabled = store.syncEnabled;
      _syncBackend = store.syncBackend;
    });
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

  Future<void> _saveSyncSettings() async {
    final store = _syncStore;
    if (store == null) return;
    await store.setSyncServerUrl(_urlController.text.trim());
    await store.setSyncApiKey(_apiKeyController.text.trim());
    await store.setSyncDeviceId(_deviceIdController.text.trim());
    await store.setSyncEncryptionPassword(_encryptionPasswordController.text);
    await store.setSyncBackend(_syncBackend);
    await store.setSyncEnabled(_syncEnabled);
    if (mounted) setState(() => _syncSettingsSaved = true);
  }

  Future<void> _syncNow() async {
    final store = _syncStore;
    if (store == null) return;
    await _saveSyncSettings();
    setState(() => _syncing = true);
    final service = SyncService(store: store, db: widget.database);
    final result = await service.syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    final message = result.ok
        ? 'Συγχρονίστηκε: ${result.pushed} στάλθηκαν, ${result.pulled} λήφθηκαν'
        : 'Αποτυχία συγχρονισμού: ${result.error}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _testConnection() async {
    final store = _syncStore;
    if (store == null) return;
    setState(() => _syncing = true);
    try {
      await store.setSyncServerUrl(_urlController.text.trim());
      await store.setSyncApiKey(_apiKeyController.text.trim());
      await store.setSyncBackend(_syncBackend);
      final service = SyncService(store: store, db: widget.database);
      await service.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Η σύνδεση λειτουργεί.')),
        );
      }
    } on SyncBackendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Αποτυχία σύνδεσης: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Αποτυχία σύνδεσης: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _serverUrlLabel() {
    switch (_syncBackend) {
      case 'pocketbase':
        return 'PocketBase URL';
      case 'custom':
        return 'Server URL (δικός σου)';
      default:
        return 'Supabase URL';
    }
  }

  String _apiKeyLabel() {
    switch (_syncBackend) {
      case 'pocketbase':
        return 'PocketBase Admin/Auth Token';
      case 'custom':
        return 'Authorization header (π.χ. Bearer xyz)';
      default:
        return 'Supabase Anon Key';
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

              // ── Συγχρονισμός ──────────────────────────────────────────────
              _header('Συγχρονισμός'),
              if (_syncStore == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SwitchListTile(
                  title: const Text('Ενεργοποίηση συγχρονισμού'),
                  subtitle: const Text('Συγχρονίζει σημειώσεις & καθημερινά μεταξύ συσκευών, κρυπτογραφημένα.'),
                  value: _syncEnabled,
                  onChanged: (v) => setState(() {
                    _syncEnabled = v;
                    _syncSettingsSaved = false;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _syncBackend,
                    decoration: const InputDecoration(
                      labelText: 'Πάροχος backend',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'supabase', child: Text('Supabase')),
                      DropdownMenuItem(value: 'pocketbase', child: Text('PocketBase')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom REST (δικός σου server)')),
                    ],
                    onChanged: (v) => setState(() {
                      _syncBackend = v ?? 'supabase';
                      _syncSettingsSaved = false;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _urlController,
                    onChanged: (_) => setState(() => _syncSettingsSaved = false),
                    decoration: InputDecoration(
                      labelText: _serverUrlLabel(),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _apiKeyController,
                    onChanged: (_) => setState(() => _syncSettingsSaved = false),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _apiKeyLabel(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _deviceIdController,
                    onChanged: (_) => setState(() => _syncSettingsSaved = false),
                    decoration: const InputDecoration(
                      labelText: 'Όνομα/ID αυτής της εγκατάστασης',
                      hintText: 'π.χ. laptop-sto-grafeio',
                      helperText: 'Χρησιμοποιείται μόνο για να ξέρεις ποια συσκευή δημιούργησε τι.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _encryptionPasswordController,
                    onChanged: (_) => setState(() => _syncSettingsSaved = false),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Κωδικός κρυπτογράφησης συγχρονισμού',
                      helperText: 'Ίδιος κωδικός σε ΟΛΕΣ τις συσκευές σου — δεν αποθηκεύεται ποτέ στο backend.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _syncing ? null : _saveSyncSettings,
                          icon: Icon(_syncSettingsSaved ? Icons.check : Icons.save_outlined),
                          label: Text(_syncSettingsSaved ? 'Αποθηκεύτηκε' : 'Αποθήκευση'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _syncing ? null : _testConnection,
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('Δοκιμή σύνδεσης'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.tonalIcon(
                    onPressed: (!_syncEnabled || _syncing) ? null : _syncNow,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Συγχρονισμός τώρα'),
                  ),
                ),
              ],
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
