import 'package:flutter/material.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/i18n.dart';
import '../../core/storage/app_database.dart';
import '../../core/sync/sync_backend.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_settings_store.dart';

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
          title: Text(tr(ctx, el: 'Ορισμός κωδικού', en: 'Set passphrase')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: c1, obscureText: true, decoration: InputDecoration(labelText: tr(ctx, el: 'Νέος κωδικός', en: 'New passphrase'))),
            const SizedBox(height: 8),
            TextField(controller: c2, obscureText: true, decoration: InputDecoration(labelText: tr(ctx, el: 'Επιβεβαίωση', en: 'Confirm'))),
            if (err != null) ...[const SizedBox(height: 8), Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr(ctx, el: 'Άκυρο', en: 'Cancel'))),
            FilledButton(
              onPressed: () {
                if (c1.text.length < 8) {
                  setS(() => err = tr(ctx, el: 'Τουλάχιστον 8 χαρακτήρες.', en: 'At least 8 characters.'));
                  return;
                }
                if (c1.text != c2.text) {
                  setS(() => err = tr(ctx, el: 'Δεν ταιριάζουν.', en: "Passwords don't match."));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(tr(ctx, el: 'Αποθήκευση', en: 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      await widget.encryptionService.initializeFromPassphrase(c1.text);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, el: 'Ο κωδικός ορίστηκε.', en: 'Passphrase set.'))),
        );
      }
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
        ? tr(context,
            el: 'Συγχρονίστηκε: ${result.pushed} στάλθηκαν, ${result.pulled} λήφθηκαν',
            en: 'Synced: ${result.pushed} pushed, ${result.pulled} pulled')
        : tr(context, el: 'Αποτυχία συγχρονισμού: ${result.error}', en: 'Sync failed: ${result.error}');
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
          SnackBar(content: Text(tr(context, el: 'Η σύνδεση λειτουργεί.', en: 'Connection works.'))),
        );
      }
    } on SyncBackendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, el: 'Αποτυχία σύνδεσης', en: 'Connection failed')}: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, el: 'Αποτυχία σύνδεσης', en: 'Connection failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _serverUrlLabel(BuildContext context) {
    switch (_syncBackend) {
      case 'pocketbase':
        return 'PocketBase URL';
      case 'custom':
        return tr(context, el: 'Server URL (δικός σου)', en: 'Server URL (your own)');
      default:
        return tr(context, el: 'Supabase URL', en: 'Supabase URL');
    }
  }

  String _apiKeyLabel(BuildContext context) {
    switch (_syncBackend) {
      case 'pocketbase':
        return tr(context, el: 'PocketBase Admin/Auth Token', en: 'PocketBase Admin/Auth Token');
      case 'custom':
        return tr(context, el: 'Authorization header (π.χ. Bearer xyz)', en: 'Authorization header (e.g. Bearer xyz)');
      default:
        return tr(context, el: 'Supabase Anon Key', en: 'Supabase Anon Key');
    }
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Ρυθμίσεις', en: 'Settings'))),
      body: _hasPassphrase == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              // ── Εμφάνιση / Appearance ────────────────────────────────────
              _header(tr(context, el: 'Εμφάνιση', en: 'Appearance')),
              RadioListTile<ThemeMode>(title: Text(tr(context, el: 'Σύστημα', en: 'System')), value: ThemeMode.system, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              RadioListTile<ThemeMode>(title: Text(tr(context, el: 'Φωτεινό', en: 'Light')), value: ThemeMode.light, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              RadioListTile<ThemeMode>(title: Text(tr(context, el: 'Σκοτεινό', en: 'Dark')), value: ThemeMode.dark, groupValue: widget.themeMode, onChanged: (m) => m != null ? widget.onThemeModeChanged(m) : null),
              const Divider(height: 32),

              // ── Γλώσσα / Language ────────────────────────────────────────
              _header(tr(context, el: 'Γλώσσα', en: 'Language')),
              RadioListTile<Locale?>(title: Text(tr(context, el: 'Σύστημα', en: 'System')), value: null, groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              RadioListTile<Locale?>(title: const Text('Ελληνικά'), value: const Locale('el'), groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              RadioListTile<Locale?>(title: const Text('English'), value: const Locale('en'), groupValue: widget.currentLocale, onChanged: widget.onLocaleChanged),
              const Divider(height: 32),

              // ── Ασφάλεια / Security ──────────────────────────────────────
              _header(tr(context, el: 'Ασφάλεια', en: 'Security')),
              ListTile(
                leading: Icon(_hasPassphrase! ? Icons.lock : Icons.lock_open),
                title: Text(tr(context, el: 'Προστασία με κωδικό', en: 'Passphrase protection')),
                subtitle: Text(_hasPassphrase!
                    ? tr(context, el: 'Ενεργή — οι σημειώσεις προστατεύονται με τον κωδικό σου.', en: 'Enabled — your notes are protected by your passphrase.')
                    : tr(context, el: 'Ανενεργή — αυτόματο κλειδί συσκευής.', en: 'Disabled — automatic device key.')),
                trailing: _hasPassphrase! ? null : FilledButton(onPressed: _setPassphraseDialog, child: Text(tr(context, el: 'Ορισμός', en: 'Set'))),
              ),
              const Divider(height: 32),

              // ── Συγχρονισμός / Sync ──────────────────────────────────────
              _header(tr(context, el: 'Συγχρονισμός', en: 'Sync')),
              if (_syncStore == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SwitchListTile(
                  title: Text(tr(context, el: 'Ενεργοποίηση συγχρονισμού', en: 'Enable sync')),
                  subtitle: Text(tr(context,
                      el: 'Συγχρονίζει σημειώσεις & καθημερινά μεταξύ συσκευών, κρυπτογραφημένα.',
                      en: 'Syncs notes & daily entries across devices, end-to-end encrypted.')),
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
                    decoration: InputDecoration(
                      labelText: tr(context, el: 'Πάροχος backend', en: 'Backend provider'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'supabase', child: Text('Supabase')),
                      const DropdownMenuItem(value: 'pocketbase', child: Text('PocketBase')),
                      DropdownMenuItem(value: 'custom', child: Text(tr(context, el: 'Custom REST (δικός σου server)', en: 'Custom REST (your own server)'))),
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
                      labelText: _serverUrlLabel(context),
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
                      labelText: _apiKeyLabel(context),
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
                    decoration: InputDecoration(
                      labelText: tr(context, el: 'Όνομα/ID αυτής της εγκατάστασης', en: 'Name/ID of this installation'),
                      hintText: tr(context, el: 'π.χ. laptop-sto-grafeio', en: 'e.g. work-laptop'),
                      helperText: tr(context,
                          el: 'Χρησιμοποιείται μόνο για να ξέρεις ποια συσκευή δημιούργησε τι.',
                          en: 'Only used so you know which device created what.'),
                      border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: tr(context, el: 'Κωδικός κρυπτογράφησης συγχρονισμού', en: 'Sync encryption passphrase'),
                      helperText: tr(context,
                          el: 'Ίδιος κωδικός σε ΟΛΕΣ τις συσκευές σου — δεν αποθηκεύεται ποτέ στο backend.',
                          en: 'Same passphrase on ALL your devices — never stored on the backend.'),
                      border: const OutlineInputBorder(),
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
                          label: Text(_syncSettingsSaved
                              ? tr(context, el: 'Αποθηκεύτηκε', en: 'Saved')
                              : tr(context, el: 'Αποθήκευση', en: 'Save')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _syncing ? null : _testConnection,
                          icon: const Icon(Icons.wifi_tethering),
                          label: Text(tr(context, el: 'Δοκιμή σύνδεσης', en: 'Test connection')),
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
                    label: Text(tr(context, el: 'Συγχρονισμός τώρα', en: 'Sync now')),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ]),
    );
  }
}
