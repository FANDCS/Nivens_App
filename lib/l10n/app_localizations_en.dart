// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Notes';

  @override
  String get notes => 'Notes';

  @override
  String get daily => 'Daily';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete note';

  @override
  String get deleteConfirmBody => 'Are you sure? This cannot be undone.';

  @override
  String get edit => 'Edit';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get statistics => 'Statistics';

  @override
  String get newNote => 'New note';

  @override
  String get untitled => 'Untitled';

  @override
  String get emptyNote => '(empty note)';

  @override
  String get noNotes => 'No notes yet.\nTap + to create one.';

  @override
  String get noEntries => 'No entries yet.\nTap + to add one.';

  @override
  String get title => 'Title';

  @override
  String get markdownHint => '# Write in markdown...';

  @override
  String get category => 'Category';

  @override
  String get addCategory => 'New category...';

  @override
  String get categories => 'Categories';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordTooShort => 'At least 8 characters required.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get security => 'Security';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get langSystem => 'System';

  @override
  String get langEl => 'Ελληνικά';

  @override
  String get langEn => 'English';

  @override
  String get passwordProtection => 'Password protection';

  @override
  String get passwordActive => 'Active — your data is protected.';

  @override
  String get passwordInactive => 'Inactive — automatic device key.';

  @override
  String get setPassword => 'Set';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get passwordSet => 'Password set.';

  @override
  String get drawing => 'Drawing';

  @override
  String get newDrawing => 'New drawing';

  @override
  String get insertDrawing => 'Insert drawing';

  @override
  String get insertImage => 'Insert image';

  @override
  String get previewMode => 'Preview';

  @override
  String get editMode => 'Edit';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get underline => 'Underline';

  @override
  String get strikethrough => 'Strikethrough';

  @override
  String get heading => 'Heading';

  @override
  String get headingNormal => 'Normal';

  @override
  String get headingH1 => 'H1 — Title';

  @override
  String get headingH2 => 'H2 — Subtitle';

  @override
  String get headingH3 => 'H3 — Small';

  @override
  String get bulletList => 'Bullet list';

  @override
  String get numberedList => 'Numbered list';

  @override
  String get taskList => 'Task list';

  @override
  String get quote => 'Quote';

  @override
  String get inlineCode => 'Inline code';

  @override
  String get codeBlock => 'Code block';

  @override
  String get exportFormat => 'Export format';

  @override
  String get exportMarkdown => 'Markdown (.md)';

  @override
  String get exportMarkdownDesc => 'Plain file, no password';

  @override
  String get exportJson => 'JSON';

  @override
  String get exportJsonDesc => 'Plain file, no password';

  @override
  String get exportQr => 'QR code';

  @override
  String get exportQrDesc => 'Plain, no password — short notes only';

  @override
  String get exportZip => 'ZIP with password';

  @override
  String get exportZipDesc => 'Encrypted';

  @override
  String get exportZipInner => 'Format inside ZIP';

  @override
  String exportedTo(String path) {
    return 'Exported: $path';
  }

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get importPickFile => 'Pick file';

  @override
  String get importSupported =>
      'Supported formats:\n.md / .txt — Markdown\n.json — JSON\n.pdf — Text extraction\n.notesbackup — Encrypted backup';

  @override
  String importSuccess(int count) {
    return '$count note(s) imported.';
  }

  @override
  String get importBackupPassword => 'Backup password';

  @override
  String importError(String error) {
    return 'Import error: $error';
  }

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeBody =>
      'Would you like to protect your data with a password?';

  @override
  String get withPassword => 'Yes, set a password';

  @override
  String get withoutPassword => 'No, continue without password';

  @override
  String get masterPassword => 'Master password';

  @override
  String get masterPasswordBody =>
      'This password encrypts all your notes. If you forget it, data cannot be recovered.';

  @override
  String get continueBtn => 'Continue';

  @override
  String get totalTab => 'Overall';

  @override
  String get monthlyTab => 'Monthly';

  @override
  String get yearlyTab => 'Yearly';

  @override
  String get totalEntries => 'Total entries';

  @override
  String get uniqueDays => 'Unique days';

  @override
  String get avgWeight => 'Average weight';

  @override
  String get density => 'Density';

  @override
  String get minWeight => 'Min weight';

  @override
  String get maxWeight => 'Max weight';

  @override
  String get byDayOfWeek => 'By day of week';

  @override
  String get byCategory => 'By category';

  @override
  String get noCategory => 'No category';

  @override
  String get byMonth => 'By month';

  @override
  String get byYear => 'By year';

  @override
  String get weightLabel => 'Weight';

  @override
  String get newEntry => 'New entry';

  @override
  String get editEntry => 'Edit';

  @override
  String get entryPlaceholder => 'What\'s on your mind today?';

  @override
  String get add => 'Add';

  @override
  String get penColor => 'Pen color';

  @override
  String get penSize => 'Pen size';

  @override
  String get eraser => 'Eraser';

  @override
  String get clearDrawing => 'Clear';

  @override
  String get saveDrawing => 'Save drawing';

  @override
  String get customColor => 'Custom color';

  @override
  String get noNotesForExport => 'No notes to export.';

  @override
  String get noEntriesForExport => 'No entries to export.';

  @override
  String get exportAllNotes => 'Export notes';

  @override
  String get exportAllDaily => 'Export daily log';

  @override
  String get importNotes => 'Import';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription =>
      'Markdown notes with encryption, media, drawing and multi-device sync — plus a daily log journal.';

  @override
  String get aboutVersion => 'Version 0.1.0';

  @override
  String get licenses => 'Licenses';

  @override
  String get builtWithFlutter => 'Built with Flutter';

  @override
  String get importScreen => 'Import';
}
