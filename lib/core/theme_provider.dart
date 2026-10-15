import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's theme choice and persists it across launches.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _restore();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _persist();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored == 'light' && _themeMode != ThemeMode.light) {
        _themeMode = ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      // Preferences unavailable (e.g. in widget tests): keep the default.
      debugPrint('ThemeProvider: could not restore theme: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('ThemeProvider: could not persist theme: $e');
    }
  }
}
