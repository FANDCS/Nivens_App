import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ρύθμιση «Καθημερινά» (ενεργά/ανενεργά). Η απενεργοποίηση ΚΡΥΒΕΙ μόνο τα
/// Καθημερινά στο UI — δεν διαγράφει τίποτα από τη βάση. Προεπιλογή: ενεργά.
class DailiesSetting {
  static const _key = 'dailies_enabled';
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Να καλείται μία φορά στην εκκίνηση (π.χ. στο main(), πριν το runApp).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_key) ?? true;
  }

  static Future<void> set(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
