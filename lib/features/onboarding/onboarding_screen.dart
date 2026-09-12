import 'package:flutter/material.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final EncryptionService encryptionService;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const OnboardingScreen({
    super.key,
    required this.encryptionService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorText;
  bool _showPassphraseForm = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _continueWithoutPassphrase() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.encryptionService.initializeWithRandomKey();
      await _openHome();
    } catch (e) {
      setState(() {
        _errorText = 'Κάτι πήγε στραβά: $e';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _openHome() async {
    final keyHex = await widget.encryptionService.getKeyHex();
    final db = AppDatabase(AppDatabase.openEncrypted(keyHex));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          database: db,
          encryptionService: widget.encryptionService,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onLocaleChanged: (_) {},
          currentLocale: null,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final passphrase = _passphraseController.text;
    final confirm = _confirmController.text;

    if (passphrase.length < 8) {
      setState(() => _errorText = 'Χρειάζεται τουλάχιστον 8 χαρακτήρες.');
      return;
    }
    if (passphrase != confirm) {
      setState(() => _errorText = 'Οι κωδικοί δεν ταιριάζουν.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.encryptionService.initializeFromPassphrase(passphrase);
      await _openHome();
    } catch (e) {
      setState(() => _errorText = 'Κάτι πήγε στραβά: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _showPassphraseForm ? _buildPassphraseForm(context) : _buildChoice(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoice(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Καλωσόρισες', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Θέλεις να προστατέψεις τις σημειώσεις σου με κωδικό;\n'
          'Χωρίς κωδικό, τα δεδομένα παραμένουν κρυπτογραφημένα με ένα '
          'κλειδί που δημιουργείται αυτόματα για τη συσκευή σου — απλά δεν '
          'θα μπορείς να τα ανοίξεις χειροκίνητα σε άλλη συσκευή με κωδικό.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSubmitting ? null : () => setState(() => _showPassphraseForm = true),
          child: const Text('Ναι, όρισε κωδικό'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSubmitting ? null : _continueWithoutPassphrase,
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Όχι, συνέχεια χωρίς κωδικό'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _buildPassphraseForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Όρισε τον master κωδικό σου',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Αυτός ο κωδικός κρυπτογραφεί όλες τις σημειώσεις σου. '
          'Δεν αποθηκεύεται πουθενά ως κείμενο — αν τον ξεχάσεις, '
          'τα δεδομένα δεν μπορούν να ανακτηθούν.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passphraseController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Master κωδικός',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: _obscure,
          decoration: const InputDecoration(
            labelText: 'Επιβεβαίωση κωδικού',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Συνέχεια'),
        ),
      ],
    );
  }
}
