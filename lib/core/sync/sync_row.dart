/// Μία γραμμή όπως αποθηκεύεται/διαβάζεται από το backend (Supabase,
/// PocketBase ή Custom REST). Το [payload] είναι ΠΑΝΤΑ το κρυπτογραφημένο
/// blob - ποτέ τα αρχικά δεδομένα (σημείωση/daily entry) σε καθαρό κείμενο.
///
/// Το ίδιο [SyncRow] format χρησιμοποιείται για ΟΛΟΥΣ τους τύπους
/// περιεχομένου του Nivens (σημειώσεις, καθημερινά, κ.λπ.) - ο διαχωρισμός
/// τύπου γίνεται μέσα στο κρυπτογραφημένο JSON (πεδίο `kind`), όχι εδώ.
class SyncRow {
  final String entryId; // σταθερό id της εγγραφής (uuid, ίδιο με το τοπικό)
  final String deviceOrigin; // ποια συσκευή το δημιούργησε (καθαρό κείμενο)
  final String payload; // κρυπτογραφημένο blob (base64)
  final DateTime updatedAt; // πότε ανέβηκε/ενημερώθηκε - χρησιμοποιείται ως cursor

  const SyncRow({
    required this.entryId,
    required this.deviceOrigin,
    required this.payload,
    required this.updatedAt,
  });
}
