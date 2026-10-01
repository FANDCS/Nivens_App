import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Λειτουργία προγραμματιστή" (Ρυθμίσεις): όταν είναι ΕΝΕΡΓΗ, το edit mode
/// της σημείωσης δείχνει το raw markdown ακριβώς όπως είναι (`**κείμενο**`,
/// `# τίτλος`, κ.λπ.) — χρήσιμο αν ξέρεις markdown και θες τον πλήρη
/// έλεγχο/προβλεψιμότητα του raw κειμένου.
///
/// Όταν είναι ΑΝΕΝΕΡΓΗ (προεπιλογή, για το κλασικό "σαν note app" feel), ο
/// [MarkdownHighlightController] κρύβει/μικραίνει τους χαρακτήρες `**`/`*`/
/// `` ` ``/`#` και αποδίδει το ανάμεσά τους κείμενο έντονο/πλάγιο/κλασικό
/// μέγεθος επικεφαλίδας ΚΑΤΑ ΤΗΝ ΕΠΕΞΕΡΓΑΣΙΑ — χωρίς να αλλάζει καθόλου το
/// πραγματικό, αποθηκευμένο markdown (which παραμένει η μοναδική πηγή
/// αλήθειας για export/sync/import).
///
/// Ένα static [ValueNotifier] (αντί για Provider/InheritedWidget) κρατάει
/// το πράγμα απλό: μία μόνο ρύθμιση, ίδια σε όλη την εφαρμογή, φορτωμένη
/// μία φορά στην εκκίνηση.
class DevMode {
  DevMode._();

  static const _key = 'developer_mode';

  /// Τρέχουσα τιμή· ξεκινάει false μέχρι να ολοκληρωθεί το [ensureLoaded].
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_key) ?? false;
    } catch (_) {
      // Αν αποτύχει η ανάγνωση, μένει στην προεπιλογή (false).
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // Best effort — η τιμή στη μνήμη έχει ήδη αλλάξει για αυτό το session.
    }
  }
}
