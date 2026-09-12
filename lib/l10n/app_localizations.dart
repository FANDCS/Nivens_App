import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In el, this message translates to:
  /// **'Σημειώσεις'**
  String get appName;

  /// No description provided for @notes.
  ///
  /// In el, this message translates to:
  /// **'Σημειώσεις'**
  String get notes;

  /// No description provided for @daily.
  ///
  /// In el, this message translates to:
  /// **'Καθημερινά'**
  String get daily;

  /// No description provided for @settings.
  ///
  /// In el, this message translates to:
  /// **'Ρυθμίσεις'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In el, this message translates to:
  /// **'Σχετικά'**
  String get about;

  /// No description provided for @save.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In el, this message translates to:
  /// **'Άκυρο'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή σημείωσης'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In el, this message translates to:
  /// **'Είσαι σίγουρος; Η ενέργεια δεν αναιρείται.'**
  String get deleteConfirmBody;

  /// No description provided for @edit.
  ///
  /// In el, this message translates to:
  /// **'Επεξεργασία'**
  String get edit;

  /// No description provided for @import.
  ///
  /// In el, this message translates to:
  /// **'Εισαγωγή'**
  String get import;

  /// No description provided for @export.
  ///
  /// In el, this message translates to:
  /// **'Εξαγωγή'**
  String get export;

  /// No description provided for @statistics.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά'**
  String get statistics;

  /// No description provided for @newNote.
  ///
  /// In el, this message translates to:
  /// **'Νέα σημείωση'**
  String get newNote;

  /// No description provided for @untitled.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς τίτλο'**
  String get untitled;

  /// No description provided for @emptyNote.
  ///
  /// In el, this message translates to:
  /// **'(κενή σημείωση)'**
  String get emptyNote;

  /// No description provided for @noNotes.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν ακόμα σημειώσεις.\nΠάτα + για να φτιάξεις μία.'**
  String get noNotes;

  /// No description provided for @noEntries.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν ακόμα καταχωρήσεις.\nΠάτα + για να προσθέσεις μία.'**
  String get noEntries;

  /// No description provided for @title.
  ///
  /// In el, this message translates to:
  /// **'Τίτλος'**
  String get title;

  /// No description provided for @markdownHint.
  ///
  /// In el, this message translates to:
  /// **'# Γράψε σε markdown...'**
  String get markdownHint;

  /// No description provided for @category.
  ///
  /// In el, this message translates to:
  /// **'Κατηγορία'**
  String get category;

  /// No description provided for @addCategory.
  ///
  /// In el, this message translates to:
  /// **'Νέα κατηγορία...'**
  String get addCategory;

  /// No description provided for @categories.
  ///
  /// In el, this message translates to:
  /// **'Κατηγορίες'**
  String get categories;

  /// No description provided for @password.
  ///
  /// In el, this message translates to:
  /// **'Κωδικός'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In el, this message translates to:
  /// **'Επιβεβαίωση κωδικού'**
  String get confirmPassword;

  /// No description provided for @newPassword.
  ///
  /// In el, this message translates to:
  /// **'Νέος κωδικός'**
  String get newPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In el, this message translates to:
  /// **'Τουλάχιστον 8 χαρακτήρες.'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In el, this message translates to:
  /// **'Οι κωδικοί δεν ταιριάζουν.'**
  String get passwordMismatch;

  /// No description provided for @appearance.
  ///
  /// In el, this message translates to:
  /// **'Εμφάνιση'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In el, this message translates to:
  /// **'Γλώσσα'**
  String get language;

  /// No description provided for @security.
  ///
  /// In el, this message translates to:
  /// **'Ασφάλεια'**
  String get security;

  /// No description provided for @themeSystem.
  ///
  /// In el, this message translates to:
  /// **'Σύστημα'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In el, this message translates to:
  /// **'Φωτεινό'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In el, this message translates to:
  /// **'Σκοτεινό'**
  String get themeDark;

  /// No description provided for @langSystem.
  ///
  /// In el, this message translates to:
  /// **'Σύστημα'**
  String get langSystem;

  /// No description provided for @langEl.
  ///
  /// In el, this message translates to:
  /// **'Ελληνικά'**
  String get langEl;

  /// No description provided for @langEn.
  ///
  /// In el, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @passwordProtection.
  ///
  /// In el, this message translates to:
  /// **'Προστασία με κωδικό'**
  String get passwordProtection;

  /// No description provided for @passwordActive.
  ///
  /// In el, this message translates to:
  /// **'Ενεργή — τα δεδομένα σου προστατεύονται.'**
  String get passwordActive;

  /// No description provided for @passwordInactive.
  ///
  /// In el, this message translates to:
  /// **'Ανενεργή — αυτόματο κλειδί συσκευής.'**
  String get passwordInactive;

  /// No description provided for @setPassword.
  ///
  /// In el, this message translates to:
  /// **'Ορισμός'**
  String get setPassword;

  /// No description provided for @setPasswordTitle.
  ///
  /// In el, this message translates to:
  /// **'Ορισμός κωδικού'**
  String get setPasswordTitle;

  /// No description provided for @passwordSet.
  ///
  /// In el, this message translates to:
  /// **'Ο κωδικός ορίστηκε.'**
  String get passwordSet;

  /// No description provided for @drawing.
  ///
  /// In el, this message translates to:
  /// **'Σχέδιο'**
  String get drawing;

  /// No description provided for @newDrawing.
  ///
  /// In el, this message translates to:
  /// **'Νέο σχέδιο'**
  String get newDrawing;

  /// No description provided for @insertDrawing.
  ///
  /// In el, this message translates to:
  /// **'Εισαγωγή σχεδίου'**
  String get insertDrawing;

  /// No description provided for @insertImage.
  ///
  /// In el, this message translates to:
  /// **'Εισαγωγή εικόνας'**
  String get insertImage;

  /// No description provided for @previewMode.
  ///
  /// In el, this message translates to:
  /// **'Προβολή'**
  String get previewMode;

  /// No description provided for @editMode.
  ///
  /// In el, this message translates to:
  /// **'Επεξεργασία'**
  String get editMode;

  /// No description provided for @undo.
  ///
  /// In el, this message translates to:
  /// **'Αναίρεση'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In el, this message translates to:
  /// **'Επαναφορά'**
  String get redo;

  /// No description provided for @bold.
  ///
  /// In el, this message translates to:
  /// **'Έντονο'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In el, this message translates to:
  /// **'Πλάγιο'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In el, this message translates to:
  /// **'Υπογράμμιση'**
  String get underline;

  /// No description provided for @strikethrough.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή'**
  String get strikethrough;

  /// No description provided for @heading.
  ///
  /// In el, this message translates to:
  /// **'Επικεφαλίδα'**
  String get heading;

  /// No description provided for @headingNormal.
  ///
  /// In el, this message translates to:
  /// **'Κανονικό'**
  String get headingNormal;

  /// No description provided for @headingH1.
  ///
  /// In el, this message translates to:
  /// **'H1 — Τίτλος'**
  String get headingH1;

  /// No description provided for @headingH2.
  ///
  /// In el, this message translates to:
  /// **'H2 — Υπότιτλος'**
  String get headingH2;

  /// No description provided for @headingH3.
  ///
  /// In el, this message translates to:
  /// **'H3 — Μικρός'**
  String get headingH3;

  /// No description provided for @bulletList.
  ///
  /// In el, this message translates to:
  /// **'Bullet list'**
  String get bulletList;

  /// No description provided for @numberedList.
  ///
  /// In el, this message translates to:
  /// **'Αριθμημένη λίστα'**
  String get numberedList;

  /// No description provided for @taskList.
  ///
  /// In el, this message translates to:
  /// **'Task list'**
  String get taskList;

  /// No description provided for @quote.
  ///
  /// In el, this message translates to:
  /// **'Παράθεση'**
  String get quote;

  /// No description provided for @inlineCode.
  ///
  /// In el, this message translates to:
  /// **'Inline κώδικας'**
  String get inlineCode;

  /// No description provided for @codeBlock.
  ///
  /// In el, this message translates to:
  /// **'Block κώδικα'**
  String get codeBlock;

  /// No description provided for @exportFormat.
  ///
  /// In el, this message translates to:
  /// **'Μορφή εξαγωγής'**
  String get exportFormat;

  /// No description provided for @exportMarkdown.
  ///
  /// In el, this message translates to:
  /// **'Markdown (.md)'**
  String get exportMarkdown;

  /// No description provided for @exportMarkdownDesc.
  ///
  /// In el, this message translates to:
  /// **'Απλό αρχείο, χωρίς κωδικό'**
  String get exportMarkdownDesc;

  /// No description provided for @exportJson.
  ///
  /// In el, this message translates to:
  /// **'JSON'**
  String get exportJson;

  /// No description provided for @exportJsonDesc.
  ///
  /// In el, this message translates to:
  /// **'Απλό αρχείο, χωρίς κωδικό'**
  String get exportJsonDesc;

  /// No description provided for @exportQr.
  ///
  /// In el, this message translates to:
  /// **'QR κωδικός'**
  String get exportQr;

  /// No description provided for @exportQrDesc.
  ///
  /// In el, this message translates to:
  /// **'Απλό, χωρίς κωδικό — μόνο για σύντομες σημειώσεις'**
  String get exportQrDesc;

  /// No description provided for @exportZip.
  ///
  /// In el, this message translates to:
  /// **'ZIP με κωδικό'**
  String get exportZip;

  /// No description provided for @exportZipDesc.
  ///
  /// In el, this message translates to:
  /// **'Κρυπτογραφημένο'**
  String get exportZipDesc;

  /// No description provided for @exportZipInner.
  ///
  /// In el, this message translates to:
  /// **'Μορφή μέσα στο ZIP'**
  String get exportZipInner;

  /// No description provided for @exportedTo.
  ///
  /// In el, this message translates to:
  /// **'Εξήχθη: {path}'**
  String exportedTo(String path);

  /// No description provided for @exportError.
  ///
  /// In el, this message translates to:
  /// **'Σφάλμα εξαγωγής: {error}'**
  String exportError(String error);

  /// No description provided for @importPickFile.
  ///
  /// In el, this message translates to:
  /// **'Επιλογή αρχείου'**
  String get importPickFile;

  /// No description provided for @importSupported.
  ///
  /// In el, this message translates to:
  /// **'Υποστηριζόμενες μορφές:\n.md / .txt — Markdown\n.json — JSON\n.pdf — Εξαγωγή κειμένου\n.notesbackup — Κρυπτογραφημένο backup'**
  String get importSupported;

  /// No description provided for @importSuccess.
  ///
  /// In el, this message translates to:
  /// **'Εισήχθη/θησαν {count} σημείωση/σεις.'**
  String importSuccess(int count);

  /// No description provided for @importBackupPassword.
  ///
  /// In el, this message translates to:
  /// **'Κωδικός backup'**
  String get importBackupPassword;

  /// No description provided for @importError.
  ///
  /// In el, this message translates to:
  /// **'Σφάλμα εισαγωγής: {error}'**
  String importError(String error);

  /// No description provided for @welcomeTitle.
  ///
  /// In el, this message translates to:
  /// **'Καλωσόρισες'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In el, this message translates to:
  /// **'Θέλεις να προστατέψεις τα δεδομένα σου με κωδικό;'**
  String get welcomeBody;

  /// No description provided for @withPassword.
  ///
  /// In el, this message translates to:
  /// **'Ναι, όρισε κωδικό'**
  String get withPassword;

  /// No description provided for @withoutPassword.
  ///
  /// In el, this message translates to:
  /// **'Όχι, χωρίς κωδικό'**
  String get withoutPassword;

  /// No description provided for @masterPassword.
  ///
  /// In el, this message translates to:
  /// **'Master κωδικός'**
  String get masterPassword;

  /// No description provided for @masterPasswordBody.
  ///
  /// In el, this message translates to:
  /// **'Αυτός ο κωδικός κρυπτογραφεί όλες τις σημειώσεις σου. Αν τον ξεχάσεις, τα δεδομένα δεν ανακτώνται.'**
  String get masterPasswordBody;

  /// No description provided for @continueBtn.
  ///
  /// In el, this message translates to:
  /// **'Συνέχεια'**
  String get continueBtn;

  /// No description provided for @totalTab.
  ///
  /// In el, this message translates to:
  /// **'Σύνολο'**
  String get totalTab;

  /// No description provided for @monthlyTab.
  ///
  /// In el, this message translates to:
  /// **'Ανά μήνα'**
  String get monthlyTab;

  /// No description provided for @yearlyTab.
  ///
  /// In el, this message translates to:
  /// **'Ανά χρόνο'**
  String get yearlyTab;

  /// No description provided for @totalEntries.
  ///
  /// In el, this message translates to:
  /// **'Σύνολο καταχωρήσεων'**
  String get totalEntries;

  /// No description provided for @uniqueDays.
  ///
  /// In el, this message translates to:
  /// **'Μοναδικές ημέρες'**
  String get uniqueDays;

  /// No description provided for @avgWeight.
  ///
  /// In el, this message translates to:
  /// **'Μέση βαρύτητα'**
  String get avgWeight;

  /// No description provided for @density.
  ///
  /// In el, this message translates to:
  /// **'Πυκνότητα'**
  String get density;

  /// No description provided for @minWeight.
  ///
  /// In el, this message translates to:
  /// **'Ελάχ. βαρύτητα'**
  String get minWeight;

  /// No description provided for @maxWeight.
  ///
  /// In el, this message translates to:
  /// **'Μέγ. βαρύτητα'**
  String get maxWeight;

  /// No description provided for @byDayOfWeek.
  ///
  /// In el, this message translates to:
  /// **'Ανά ημέρα εβδομάδας'**
  String get byDayOfWeek;

  /// No description provided for @byCategory.
  ///
  /// In el, this message translates to:
  /// **'Ανά κατηγορία'**
  String get byCategory;

  /// No description provided for @noCategory.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς κατηγορία'**
  String get noCategory;

  /// No description provided for @byMonth.
  ///
  /// In el, this message translates to:
  /// **'Ανά μήνα'**
  String get byMonth;

  /// No description provided for @byYear.
  ///
  /// In el, this message translates to:
  /// **'Ανά χρόνο'**
  String get byYear;

  /// No description provided for @weightLabel.
  ///
  /// In el, this message translates to:
  /// **'Βαρύτητα'**
  String get weightLabel;

  /// No description provided for @newEntry.
  ///
  /// In el, this message translates to:
  /// **'Νέα καταχώρηση'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In el, this message translates to:
  /// **'Επεξεργασία'**
  String get editEntry;

  /// No description provided for @entryPlaceholder.
  ///
  /// In el, this message translates to:
  /// **'Τι σε απασχόλησε σήμερα;'**
  String get entryPlaceholder;

  /// No description provided for @add.
  ///
  /// In el, this message translates to:
  /// **'Προσθήκη'**
  String get add;

  /// No description provided for @penColor.
  ///
  /// In el, this message translates to:
  /// **'Χρώμα πινέλου'**
  String get penColor;

  /// No description provided for @penSize.
  ///
  /// In el, this message translates to:
  /// **'Μέγεθος πινέλου'**
  String get penSize;

  /// No description provided for @eraser.
  ///
  /// In el, this message translates to:
  /// **'Γόμα'**
  String get eraser;

  /// No description provided for @clearDrawing.
  ///
  /// In el, this message translates to:
  /// **'Καθαρισμός'**
  String get clearDrawing;

  /// No description provided for @saveDrawing.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση σχεδίου'**
  String get saveDrawing;

  /// No description provided for @customColor.
  ///
  /// In el, this message translates to:
  /// **'Επιλογή χρώματος'**
  String get customColor;

  /// No description provided for @noNotesForExport.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν σημειώσεις για εξαγωγή.'**
  String get noNotesForExport;

  /// No description provided for @noEntriesForExport.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν καταχωρήσεις για εξαγωγή.'**
  String get noEntriesForExport;

  /// No description provided for @exportAllNotes.
  ///
  /// In el, this message translates to:
  /// **'Εξαγωγή σημειώσεων'**
  String get exportAllNotes;

  /// No description provided for @exportAllDaily.
  ///
  /// In el, this message translates to:
  /// **'Εξαγωγή καθημερινών'**
  String get exportAllDaily;

  /// No description provided for @importNotes.
  ///
  /// In el, this message translates to:
  /// **'Εισαγωγή'**
  String get importNotes;

  /// No description provided for @statsTitle.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά'**
  String get statsTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In el, this message translates to:
  /// **'Σχετικά'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In el, this message translates to:
  /// **'Σημειώσεις σε markdown με κρυπτογράφηση, πολυμέσα, ζωγραφική και συγχρονισμό μεταξύ συσκευών — μαζί με ημερολόγιο καθημερινών σχολίων.'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In el, this message translates to:
  /// **'Έκδοση 0.1.0'**
  String get aboutVersion;

  /// No description provided for @licenses.
  ///
  /// In el, this message translates to:
  /// **'Άδειες χρήσης'**
  String get licenses;

  /// No description provided for @builtWithFlutter.
  ///
  /// In el, this message translates to:
  /// **'Φτιαγμένο με Flutter'**
  String get builtWithFlutter;

  /// No description provided for @importScreen.
  ///
  /// In el, this message translates to:
  /// **'Εισαγωγή'**
  String get importScreen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
