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
- Supabase sync: service έτοιμο (core/sync/supabase_sync_service.dart),
  δεν είναι ακόμα καλωδιωμένο σε UI trigger

## Επόμενα βήματα

- [ ] Import/restore από .notesbackup αρχείο
- [ ] Καλωδίωση SupabaseSyncService σε background trigger
- [ ] Πλούσιο rich-text editor (πάνω από markdown) — attachments, ζωγραφική
- [ ] Γραμματοσειρές ανά σημείωση
