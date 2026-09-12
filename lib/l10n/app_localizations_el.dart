// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appName => 'Σημειώσεις';

  @override
  String get notes => 'Σημειώσεις';

  @override
  String get daily => 'Καθημερινά';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get about => 'Σχετικά';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get cancel => 'Άκυρο';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get deleteConfirmTitle => 'Διαγραφή σημείωσης';

  @override
  String get deleteConfirmBody => 'Είσαι σίγουρος; Η ενέργεια δεν αναιρείται.';

  @override
  String get edit => 'Επεξεργασία';

  @override
  String get import => 'Εισαγωγή';

  @override
  String get export => 'Εξαγωγή';

  @override
  String get statistics => 'Στατιστικά';

  @override
  String get newNote => 'Νέα σημείωση';

  @override
  String get untitled => 'Χωρίς τίτλο';

  @override
  String get emptyNote => '(κενή σημείωση)';

  @override
  String get noNotes =>
      'Δεν υπάρχουν ακόμα σημειώσεις.\nΠάτα + για να φτιάξεις μία.';

  @override
  String get noEntries =>
      'Δεν υπάρχουν ακόμα καταχωρήσεις.\nΠάτα + για να προσθέσεις μία.';

  @override
  String get title => 'Τίτλος';

  @override
  String get markdownHint => '# Γράψε σε markdown...';

  @override
  String get category => 'Κατηγορία';

  @override
  String get addCategory => 'Νέα κατηγορία...';

  @override
  String get categories => 'Κατηγορίες';

  @override
  String get password => 'Κωδικός';

  @override
  String get confirmPassword => 'Επιβεβαίωση κωδικού';

  @override
  String get newPassword => 'Νέος κωδικός';

  @override
  String get passwordTooShort => 'Τουλάχιστον 8 χαρακτήρες.';

  @override
  String get passwordMismatch => 'Οι κωδικοί δεν ταιριάζουν.';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get language => 'Γλώσσα';

  @override
  String get security => 'Ασφάλεια';

  @override
  String get themeSystem => 'Σύστημα';

  @override
  String get themeLight => 'Φωτεινό';

  @override
  String get themeDark => 'Σκοτεινό';

  @override
  String get langSystem => 'Σύστημα';

  @override
  String get langEl => 'Ελληνικά';

  @override
  String get langEn => 'English';

  @override
  String get passwordProtection => 'Προστασία με κωδικό';

  @override
  String get passwordActive => 'Ενεργή — τα δεδομένα σου προστατεύονται.';

  @override
  String get passwordInactive => 'Ανενεργή — αυτόματο κλειδί συσκευής.';

  @override
  String get setPassword => 'Ορισμός';

  @override
  String get setPasswordTitle => 'Ορισμός κωδικού';

  @override
  String get passwordSet => 'Ο κωδικός ορίστηκε.';

  @override
  String get drawing => 'Σχέδιο';

  @override
  String get newDrawing => 'Νέο σχέδιο';

  @override
  String get insertDrawing => 'Εισαγωγή σχεδίου';

  @override
  String get insertImage => 'Εισαγωγή εικόνας';

  @override
  String get previewMode => 'Προβολή';

  @override
  String get editMode => 'Επεξεργασία';

  @override
  String get undo => 'Αναίρεση';

  @override
  String get redo => 'Επαναφορά';

  @override
  String get bold => 'Έντονο';

  @override
  String get italic => 'Πλάγιο';

  @override
  String get underline => 'Υπογράμμιση';

  @override
  String get strikethrough => 'Διαγραφή';

  @override
  String get heading => 'Επικεφαλίδα';

  @override
  String get headingNormal => 'Κανονικό';

  @override
  String get headingH1 => 'H1 — Τίτλος';

  @override
  String get headingH2 => 'H2 — Υπότιτλος';

  @override
  String get headingH3 => 'H3 — Μικρός';

  @override
  String get bulletList => 'Bullet list';

  @override
  String get numberedList => 'Αριθμημένη λίστα';

  @override
  String get taskList => 'Task list';

  @override
  String get quote => 'Παράθεση';

  @override
  String get inlineCode => 'Inline κώδικας';

  @override
  String get codeBlock => 'Block κώδικα';

  @override
  String get exportFormat => 'Μορφή εξαγωγής';

  @override
  String get exportMarkdown => 'Markdown (.md)';

  @override
  String get exportMarkdownDesc => 'Απλό αρχείο, χωρίς κωδικό';

  @override
  String get exportJson => 'JSON';

  @override
  String get exportJsonDesc => 'Απλό αρχείο, χωρίς κωδικό';

  @override
  String get exportQr => 'QR κωδικός';

  @override
  String get exportQrDesc =>
      'Απλό, χωρίς κωδικό — μόνο για σύντομες σημειώσεις';

  @override
  String get exportZip => 'ZIP με κωδικό';

  @override
  String get exportZipDesc => 'Κρυπτογραφημένο';

  @override
  String get exportZipInner => 'Μορφή μέσα στο ZIP';

  @override
  String exportedTo(String path) {
    return 'Εξήχθη: $path';
  }

  @override
  String exportError(String error) {
    return 'Σφάλμα εξαγωγής: $error';
  }

  @override
  String get importPickFile => 'Επιλογή αρχείου';

  @override
  String get importSupported =>
      'Υποστηριζόμενες μορφές:\n.md / .txt — Markdown\n.json — JSON\n.pdf — Εξαγωγή κειμένου\n.notesbackup — Κρυπτογραφημένο backup';

  @override
  String importSuccess(int count) {
    return 'Εισήχθη/θησαν $count σημείωση/σεις.';
  }

  @override
  String get importBackupPassword => 'Κωδικός backup';

  @override
  String importError(String error) {
    return 'Σφάλμα εισαγωγής: $error';
  }

  @override
  String get welcomeTitle => 'Καλωσόρισες';

  @override
  String get welcomeBody => 'Θέλεις να προστατέψεις τα δεδομένα σου με κωδικό;';

  @override
  String get withPassword => 'Ναι, όρισε κωδικό';

  @override
  String get withoutPassword => 'Όχι, χωρίς κωδικό';

  @override
  String get masterPassword => 'Master κωδικός';

  @override
  String get masterPasswordBody =>
      'Αυτός ο κωδικός κρυπτογραφεί όλες τις σημειώσεις σου. Αν τον ξεχάσεις, τα δεδομένα δεν ανακτώνται.';

  @override
  String get continueBtn => 'Συνέχεια';

  @override
  String get totalTab => 'Σύνολο';

  @override
  String get monthlyTab => 'Ανά μήνα';

  @override
  String get yearlyTab => 'Ανά χρόνο';

  @override
  String get totalEntries => 'Σύνολο καταχωρήσεων';

  @override
  String get uniqueDays => 'Μοναδικές ημέρες';

  @override
  String get avgWeight => 'Μέση βαρύτητα';

  @override
  String get density => 'Πυκνότητα';

  @override
  String get minWeight => 'Ελάχ. βαρύτητα';

  @override
  String get maxWeight => 'Μέγ. βαρύτητα';

  @override
  String get byDayOfWeek => 'Ανά ημέρα εβδομάδας';

  @override
  String get byCategory => 'Ανά κατηγορία';

  @override
  String get noCategory => 'Χωρίς κατηγορία';

  @override
  String get byMonth => 'Ανά μήνα';

  @override
  String get byYear => 'Ανά χρόνο';

  @override
  String get weightLabel => 'Βαρύτητα';

  @override
  String get newEntry => 'Νέα καταχώρηση';

  @override
  String get editEntry => 'Επεξεργασία';

  @override
  String get entryPlaceholder => 'Τι σε απασχόλησε σήμερα;';

  @override
  String get add => 'Προσθήκη';

  @override
  String get penColor => 'Χρώμα πινέλου';

  @override
  String get penSize => 'Μέγεθος πινέλου';

  @override
  String get eraser => 'Γόμα';

  @override
  String get clearDrawing => 'Καθαρισμός';

  @override
  String get saveDrawing => 'Αποθήκευση σχεδίου';

  @override
  String get customColor => 'Επιλογή χρώματος';

  @override
  String get noNotesForExport => 'Δεν υπάρχουν σημειώσεις για εξαγωγή.';

  @override
  String get noEntriesForExport => 'Δεν υπάρχουν καταχωρήσεις για εξαγωγή.';

  @override
  String get exportAllNotes => 'Εξαγωγή σημειώσεων';

  @override
  String get exportAllDaily => 'Εξαγωγή καθημερινών';

  @override
  String get importNotes => 'Εισαγωγή';

  @override
  String get statsTitle => 'Στατιστικά';

  @override
  String get aboutTitle => 'Σχετικά';

  @override
  String get aboutDescription =>
      'Σημειώσεις σε markdown με κρυπτογράφηση, πολυμέσα, ζωγραφική και συγχρονισμό μεταξύ συσκευών — μαζί με ημερολόγιο καθημερινών σχολίων.';

  @override
  String get aboutVersion => 'Έκδοση 0.1.0';

  @override
  String get licenses => 'Άδειες χρήσης';

  @override
  String get builtWithFlutter => 'Φτιαγμένο με Flutter';

  @override
  String get importScreen => 'Εισαγωγή';
}
