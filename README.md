# Notes App

## Τρέξιμο (μετά από flutter create --platforms=android,linux,windows notes_app)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --release -d <device>
```

## Android-specific setup

Δες ANDROID_SETUP.md για AGP/Kotlin/Gradle versions, permissions, και το
ιστορικό των προβλημάτων/λύσεων που αντιμετωπίσαμε (jni/record, sqlite3 vs
sqlcipher conflict, κ.λπ.)

## Τρέχουσα κατάσταση λειτουργιών

- Onboarding: προαιρετικός master κωδικός (ή αυτόματο κλειδί συσκευής)
- Σημειώσεις: markdown editor, tags/κατηγορίες, delete, export (encrypted)
- Καθημερινά: quick-add, edit, delete, tags/κατηγορίες, export (encrypted)
- Encrypted export (.notesbackup): μία σημείωση / όλες τις σημειώσεις / όλα
  τα καθημερινά — password-protected (AES-256-GCM + Argon2id)
- Συγχρονισμός: pluggable multi-backend σύστημα (Supabase / PocketBase /
  Custom REST) με end-to-end κρυπτογράφηση AES-256-GCM ανά εγγραφή,
  καλωδιωμένο στις Ρυθμίσεις (ενότητα "Συγχρονισμός") — δες core/sync/
  και sync-backend/*.md. Συγχρονίζει σημειώσεις και καθημερινά
- Native note format: **.fnotes** (πρώην .md) — YAML front-matter + markdown
  σώμα, δες `NoteDocument.toMarkdownFile()`/`fromMarkdownFile()`
- Εξαγωγή σημείωσης: .fnotes, JSON, **PDF**, **Εκτύπωση** (μέσω `printing`,
  ίδιο PDF), QR (χωρίς κωδικό, για σύντομες σημειώσεις), termbin.com, ή ZIP
  με κωδικό (.fnotes/JSON μέσα) — δες `features/export/`
- Εισαγωγή: .fnotes, .md/.txt, **.doc** (Word 97-2003, δικός μας OLE2/CFB +
  FIB parser χωρίς εξωτερικό πακέτο — μόνο κείμενο), .docx, .json, .pdf,
  .notesbackup, και **QR** (σάρωση κάμερας σε Android/iOS/macOS, ή
  επικόλληση κειμένου παντού) — δες `features/import/doc_reader.dart` και
  `features/export/qr_import_dialog.dart`
- **Μετατροπή κωδικοποίησης αρχείου**: ανιχνεύει (ή ορίζεις εσύ) την πηγή
  ενός οποιουδήποτε αρχείου κειμένου (UTF-8/16, Windows-1253/1252/1251,
  ISO-8859-7/1) και το αποθηκεύει σε άλλη κωδικοποίηση, με προεπισκόπηση
  πριν την αποθήκευση — δες `core/text_encoding.dart` και
  `features/export/encoding_converter_screen.dart`. Ανεξάρτητο εργαλείο,
  δεν αγγίζει τα δεδομένα της εφαρμογής

## Νέα (αυτή η έκδοση)

- **Ζουμ στην Προβολή**: pinch, κουμπιά +/− με ένδειξη ποσοστού, διπλό
  πάτημα για 100% ↔ 250%, εύρος 50%–800%, σύρσιμο (pan) όταν είσαι
  ζουμαρισμένος.
- **Ζωγραφική σε πάνω layer**: η «Ζωγραφική πάνω σε όλα» αποθηκεύεται πλέον
  ως ξεχωριστό PNG με διάφανο φόντο (`overlay` στο front-matter) και
  αποδίδεται ΠΑΝΩ από κείμενο και πολυμέσα, χωρίς να αλλοιώνει το markdown.
  Μπορείς να το κρύψεις/εμφανίσεις ή να το διαγράψεις.
- **Γραμματοσειρές ανά σημείωση**: ~28 γραμματοσειρές (Google Fonts, με
  υποστήριξη ελληνικών) με picker και ζωντανή προεπισκόπηση — εφαρμόζονται
  και στον editor και στην Προβολή.
- **Άνοιγμα Word (.docx)**: εξαγωγή σε markdown (επικεφαλίδες, έντονα/
  πλάγια, λίστες, πίνακες) + εξαγωγή των ενσωματωμένων εικόνων.
- **Άνοιγμα από την εξερεύνηση αρχείων**: η εφαρμογή εμφανίζεται στο
  «Άνοιγμα με...» για PDF, .docx, .md, .txt (intent-filters + MainActivity).
- **Upload στο termbin.com**: Εξαγωγή → «Ανέβασμα στο termbin.com» (TCP
  9999) και επιστροφή δημόσιου link. Προσοχή: χωρίς κρυπτογράφηση.

## Επόμενα βήματα

- [x] Import/restore από .notesbackup αρχείο
- [ ] Αυτόματος (background) συγχρονισμός — προς το παρόν μόνο χειροκίνητο
      "Συγχρονισμός τώρα" στις Ρυθμίσεις
- [ ] Πλούσιο rich-text editor (πάνω από markdown) — attachments
- [x] Γραμματοσειρές ανά σημείωση
- [x] Ζωγραφική ως πάνω layer + ζουμ στην Προβολή
- [x] Υποστήριξη παλιού binary .doc (Word 97-2003) — μόνο κείμενο
- [x] Εξαγωγή ως PDF + Εκτύπωση
- [x] Εισαγωγή μέσω QR (κάμερα ή επικόλληση)
- [x] Μετατροπή κωδικοποίησης αρχείου (UTF-8/16, Windows-125x, ISO-8859-x)
- [x] Native format μετονομάστηκε σε .fnotes (πρώην .md)
- [x] Tappable task-list checkboxes στην Προβολή (πριν ήταν μόνο στατικά)
