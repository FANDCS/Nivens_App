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
  ίδιο PDF), **Εικόνα/ες (PNG)**, **Αντιγραφή στο πρόχειρο**, QR (χωρίς
  κωδικό, για σύντομες σημειώσεις), termbin.com, ή ZIP με κωδικό
  (.fnotes/JSON μέσα) — δες `features/export/`
  - **PDF / Εκτύπωση**: ρωτάει αν θα εξαχθεί η **Προβολή (review)** —
    αποδοσμένο markdown, με τη ζωγραφιά σε δική της σελίδα — ή η
    **Επεξεργασία (edit mode)** — το κείμενο όπως φαίνεται στον editor, με τα
    σύμβολα markdown (με την ίδια ελαφριά μορφοποίηση του editor όταν η
    «Λειτουργία προγραμματιστή» είναι ανενεργή, αλλιώς καθαρό κείμενο). Το
    PDF της επεξεργασίας αποθηκεύεται ως `<τίτλος>_edit.pdf`.
  - **Αντιγραφή στο πρόχειρο**: το κείμενο της σημείωσης ακριβώς όπως είναι
    στον editor (raw markdown, χωρίς τίτλο/front-matter).
  - **Εικόνα/ες (PNG)**: «σαν screenshot» της ΤΡΕΧΟΥΣΑΣ λειτουργίας — αν
    είσαι στην Προβολή βγαίνει η Προβολή, αν είσαι στην Επεξεργασία βγαίνει
    η Επεξεργασία (ολόκληρο το κείμενο, όχι μόνο το ορατό μέρος). Αν η
    σημείωση είναι μεγάλη κόβεται σε πολλές εικόνες (ως ~4000px η καθεμία,
    στην Επεξεργασία η κοπή γίνεται ανάμεσα σε γραμμές). Αποθηκεύονται στο
    `Documents/Nivens/exports` — δες `features/export/image_export_service.dart`.
- Εισαγωγή: .fnotes, .md/.txt, **.doc** (Word 97-2003, δικός μας OLE2/CFB +
  FIB parser χωρίς εξωτερικό πακέτο — μόνο κείμενο), .docx, .json, .pdf,
  .notesbackup, και **QR** (σάρωση κάμερας σε Android/iOS/macOS, ή
  επικόλληση κειμένου παντού) — δες `features/import/doc_reader.dart` και
  `features/export/qr_import_dialog.dart`
- **Μετατροπή κωδικοποίησης αρχείου**: ανιχνεύει (ή ορίζεις εσύ) την πηγή
  ενός οποιουδήποτε αρχείου κειμένου και το αποθηκεύει σε άλλη
  κωδικοποίηση, με προεπισκόπηση και προειδοποίηση αν κάποιοι χαρακτήρες
  δεν χωράνε στην κωδικοποίηση-στόχο (θα γίνουν «?»). Υποστηρίζονται ~50
  κωδικοποιήσεις, ομαδοποιημένες στον διάλογο επιλογής:
  Unicode (UTF-8, UTF-8 BOM, UTF-16 LE/BE, **UTF-32 LE/BE**, US-ASCII),
  Ελληνικά (Windows-1253, ISO-8859-7, CP737, CP869, Mac Greek),
  Δυτικοευρωπαϊκά (Windows-1252, ISO-8859-1/15/10/14/3, CP437/850/858/860/
  861/863/865, Mac Roman), Κεντρικής Ευρώπης (Windows-1250, ISO-8859-2/16,
  CP852, Mac CE), Βαλτικά (Windows-1257, ISO-8859-13/4, CP775), Κυριλλικά
  (Windows-1251, ISO-8859-5, KOI8-R/U, CP866, CP855, Mac Cyrillic),
  Τουρκικά, Εβραϊκά, Αραβικά, Βιετναμέζικα/Ταϊλανδέζικα. Δεν υποστηρίζονται
  ακόμα οι πολυψήφιες ανατολικοασιατικές (Shift_JIS, GBK, Big5, EUC-KR).
  Δες `core/text_encoding.dart`, `core/text_encoding_tables.dart` (παραγόμενο
  αρχείο με τους πίνακες των μονοψήφιων κωδικοποιήσεων),
  `features/export/encoding_picker.dart` και
  `features/export/encoding_converter_screen.dart`. Ανεξάρτητο εργαλείο,
  δεν αγγίζει τα δεδομένα της εφαρμογής. Η ίδια λίστα εμφανίζεται και στο
  «Αλλαγή κωδικοποίησης αρχείου» του editor

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
- [x] Μετατροπή κωδικοποίησης αρχείου (Unicode, Windows-125x, ISO-8859-x, DOS/OEM, KOI8, Mac)
- [x] PDF/Εκτύπωση: επιλογή review ή edit mode
- [x] Εξαγωγή ως εικόνα/ες PNG (ακολουθεί Προβολή/Επεξεργασία) + αντιγραφή στο πρόχειρο
- [ ] Πολυψήφιες κωδικοποιήσεις (Shift_JIS, GBK, Big5, EUC-KR)
- [x] Native format μετονομάστηκε σε .fnotes (πρώην .md)
- [x] Tappable task-list checkboxes στην Προβολή (πριν ήταν μόνο στατικά)
