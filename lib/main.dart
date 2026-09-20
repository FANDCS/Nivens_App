import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'core/encryption/encryption_service.dart';
import 'core/storage/app_database.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/notes/note_editor_screen.dart';
import 'features/import/docx_reader.dart';
import 'features/pdf/pdf_viewer_screen.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ενεργοποιείται μετά από flutter pub get + gen

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Δωρεάν "Community License" key από τη Syncfusion — χρειάζεται ΜΟΝΟ αν
/// χρησιμοποιείς οπτικά widgets τους (π.χ. το SfPdfViewer της νέας
/// "Προβολή ως PDF"), αλλιώς εμφανίζεται banner δοκιμαστικής έκδοσης.
/// Βγάλε ΔΩΡΕΑΝ κλειδί (community license) από:
/// https://www.syncfusion.com/sales/communitylicense
/// και πέρασέ το είτε εδώ είτε (καλύτερα) μέσω
/// --dart-define=SYNCFUSION_LICENSE_KEY=... ώστε να μη μπει στο git.
const syncfusionLicenseKey = String.fromEnvironment('SYNCFUSION_LICENSE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Η καταχώριση του Syncfusion license έχει μετακινηθεί σε ξεχωριστό
  // πακέτο (syncfusion_licensing) και ΔΕΝ υπάρχει στο
  // syncfusion_flutter_core 31.2.18 που χρησιμοποιεί το project. Αν θέλεις
  // να φύγει το trial banner, πρόσθεσε `syncfusion_licensing` στο
  // pubspec.yaml και ξε-σχολίασε τις δύο γραμμές (μαζί με το import).
  // if (syncfusionLicenseKey.isNotEmpty) {
  //   SyncfusionLicense.registerLicense(syncfusionLicenseKey);
  // }
  final prefs = await SharedPreferences.getInstance();

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  final encryptionService = EncryptionService();
  runApp(NotesApp(encryptionService: encryptionService, prefs: prefs));
}

class NotesApp extends StatefulWidget {
  final EncryptionService encryptionService;
  final SharedPreferences prefs;
  const NotesApp({super.key, required this.encryptionService, required this.prefs});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null = σύστημα

  @override
  void initState() {
    super.initState();
    // Φόρτωσε αποθηκευμένες προτιμήσεις
    final savedTheme = widget.prefs.getString('theme_mode');
    if (savedTheme == 'light') _themeMode = ThemeMode.light;
    if (savedTheme == 'dark') _themeMode = ThemeMode.dark;

    final savedLang = widget.prefs.getString('language');
    if (savedLang == 'el') _locale = const Locale('el');
    if (savedLang == 'en') _locale = const Locale('en');
  }

  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.prefs.setString('theme_mode', mode.name);
  }

  void _changeLocale(Locale? locale) {
    setState(() => _locale = locale);
    widget.prefs.setString('language', locale?.languageCode ?? 'system');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      locale: _locale,
      // Localizations — ενεργοποιημένο όταν έχουν γίνει generate τα ARB
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // AppLocalizations.delegate, // uncomment μετά το flutter gen-l10n
      ],
      supportedLocales: const [
        Locale('el'),
        Locale('en'),
      ],
      home: _RootRouter(
        encryptionService: widget.encryptionService,
        prefs: widget.prefs,
        themeMode: _themeMode,
        onThemeModeChanged: _changeTheme,
        onLocaleChanged: _changeLocale,
        currentLocale: _locale,
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  final EncryptionService encryptionService;
  final SharedPreferences prefs;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final Locale? currentLocale;

  const _RootRouter({
    required this.encryptionService,
    required this.prefs,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  static const _intentChannel = MethodChannel('notes_app/intent');
  String? _intentFilePath;
  bool _quickNote = false;

  @override
  void initState() {
    super.initState();
    _checkIncomingIntent();
  }

  Future<void> _checkIncomingIntent() async {
    // Αρχείο με το οποίο ξεκίνησε η εφαρμογή
    try {
      final path = await _intentChannel.invokeMethod<String?>('getInitialFile');
      if (path != null && mounted) setState(() => _intentFilePath = path);
    } catch (_) {}
    // "Γρήγορη σημείωση" από shortcut/quick-settings tile, αν έτσι ξεκίνησε η εφαρμογή
    try {
      final action = await _intentChannel.invokeMethod<String?>('getLaunchAction');
      if (action == 'quick_note' && mounted) setState(() => _quickNote = true);
    } catch (_) {}
    // Αρχείο που ανοίχτηκε (ή "Γρήγορη σημείωση") ενώ η εφαρμογή έτρεχε ήδη
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened' && call.arguments is String && mounted) {
        setState(() {
          _intentFilePath = call.arguments as String;
          _quickNote = false;
          _pdfChoiceMade = false;
          _pdfViewOnly = false;
        });
      } else if (call.method == 'onQuickNote' && mounted) {
        setState(() {
          _quickNote = true;
          _intentFilePath = null;
        });
      }
      return null;
    });
  }

  /// Διαβάζει το αρχείο που ήρθε από την εξερεύνηση αρχείων και το
  /// μετατρέπει σε (τίτλος, περιεχόμενο markdown).
  /// Υποστηρίζονται: .pdf (εξαγωγή κειμένου), .docx (Word), .md/.txt/άλλα.
  Future<(String, String)?> _readIntentFile(String path) async {
    final file = File(path);
    final ext = path.split('.').last.toLowerCase();
    final baseName = path.split('/').last.replaceAll(RegExp(r'\.\w+$'), '');
    try {
      if (ext == 'pdf') {
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(doc);
        final buf = StringBuffer();
        for (var i = 0; i < doc.pages.count; i++) {
          buf.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
        }
        doc.dispose();
        return (baseName, buf.toString());
      } else if (ext == 'docx') {
        final docx = await DocxReader.readFile(file);
        return (baseName, docx.markdownWithImages);
      } else {
        final content = await file.readAsString();
        return (baseName, content);
      }
    } catch (_) { return null; }
  }

  /// Όταν ανοίγει PDF από την εξερεύνηση αρχείων, ρωτάμε αν θέλει
  /// προβολή του PDF ή εξαγωγή κειμένου σε νέα σημείωση.
  bool _pdfChoiceMade = false;
  bool _pdfViewOnly = false;

  Future<void> _askPdfAction() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SimpleDialog(
        title: const Text('Άνοιγμα PDF'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('view'),
            child: const Row(children: [
              Icon(Icons.picture_as_pdf_outlined), SizedBox(width: 12), Text('Προβολή ως PDF'),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('text'),
            child: const Row(children: [
              Icon(Icons.note_add_outlined), SizedBox(width: 12), Text('Εξαγωγή κειμένου σε σημείωση'),
            ]),
          ),
        ],
      ),
    );
    if (mounted) {
      setState(() {
        _pdfChoiceMade = true;
        _pdfViewOnly = choice != 'text';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: widget.encryptionService.hasKey(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.data == false) {
          return OnboardingScreen(
            encryptionService: widget.encryptionService,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        }
        return FutureBuilder<String>(
          future: widget.encryptionService.getKeyHex(),
          builder: (context, keySnapshot) {
            if (!keySnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            final db = AppDatabase(AppDatabase.openEncrypted(keySnapshot.data!));

            if (_quickNote) {
              return NoteEditorScreen(
                database: db,
                encryptionService: widget.encryptionService,
              );
            }

            if (_intentFilePath != null) {
              final isPdf = _intentFilePath!.toLowerCase().endsWith('.pdf');
              if (isPdf && !_pdfChoiceMade) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_pdfChoiceMade) _askPdfAction();
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (isPdf && _pdfViewOnly) {
                return PdfViewerScreen(
                  filePath: _intentFilePath!,
                  title: _intentFilePath!.split('/').last,
                );
              }
              return FutureBuilder<(String, String)?>(
                future: _readIntentFile(_intentFilePath!),
                builder: (context, fileSnapshot) {
                  if (!fileSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  final data = fileSnapshot.data;
                  if (data == null) return _buildHome(db);
                  return NoteEditorScreen(
                    database: db,
                    encryptionService: widget.encryptionService,
                    initialTitle: data.$1,
                    initialContent: data.$2,
                  );
                },
              );
            }
            return _buildHome(db);
          },
        );
      },
    );
  }

  Widget _buildHome(AppDatabase db) => HomeScreen(
    database: db,
    encryptionService: widget.encryptionService,
    themeMode: widget.themeMode,
    onThemeModeChanged: widget.onThemeModeChanged,
    onLocaleChanged: widget.onLocaleChanged,
    currentLocale: widget.currentLocale,
  );
}
