import 'package:flutter/material.dart';

/// Πολύ ελαφρύ βοήθημα διγλωσσίας (Ελληνικά/Αγγλικά) για σημεία της
/// εφαρμογής που δεν περνάνε (ακόμα) από το πλήρες σύστημα localization
/// (τα ARB αρχεία στο lib/l10n). Διαβάζει το ενεργό locale του
/// MaterialApp (el/en) και επιστρέφει το κατάλληλο κείμενο.
///
/// Χρήση:
///   Text(tr(context, el: 'Αποθήκευση', en: 'Save'))
String tr(BuildContext context, {required String el, required String en}) {
  final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'el';
  return code == 'en' ? en : el;
}

/// Ίδιο, αλλά επιστρέφει "Ελληνικά · English" ενωμένα με ' / ' — χρήσιμο
/// για ετικέτες/κουμπιά που θέλουμε ΠΑΝΤΑ ορατά και στις δύο γλώσσες
/// ταυτόχρονα (π.χ. σε ένα toolbar που δεν ακολουθεί το locale, ή όταν
/// θέλουμε μηδενική αμφισημία ανεξαρτήτως γλώσσας συσκευής).
String trBoth(String el, String en) => '$el / $en';
