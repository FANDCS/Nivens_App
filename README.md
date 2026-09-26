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

- [ ] Import/restore από .notesbackup αρχείο
- [ ] Καλωδίωση SupabaseSyncService σε background trigger
- [ ] Πλούσιο rich-text editor (πάνω από markdown) — attachments
- [x] Γραμματοσειρές ανά σημείωση
- [x] Ζωγραφική ως πάνω layer + ζουμ στην Προβολή
- [ ] Υποστήριξη παλιού binary .doc (Word 97-2003)
