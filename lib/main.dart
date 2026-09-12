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
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ενεργοποιείται μετά από flutter pub get + gen

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _checkIncomingIntent();
  }

  Future<void> _checkIncomingIntent() async {
    try {
      final path = await _intentChannel.invokeMethod<String?>('getInitialFile');
      if (path != null && mounted) setState(() => _intentFilePath = path);
    } catch (_) {}
  }

  Future<(String, String)?> _readIntentFile(String path) async {
    final file = File(path);
    final ext = path.split('.').last.toLowerCase();
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
        return (path.split('/').last.replaceAll('.pdf', ''), buf.toString());
      } else {
        final content = await file.readAsString();
        return (path.split('/').last.replaceAll(RegExp(r'\.\w+$'), ''), content);
      }
    } catch (_) { return null; }
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

            if (_intentFilePath != null) {
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
