import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's theme choice (system / light / dark) and persists it
/// across launches.
///
/// [isDark] always answers for the *resolved* theme: when the mode is
/// [ThemeMode.system] it follows the platform brightness, and listeners are
/// notified when that brightness changes.
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _prefsKey = 'theme_mode';

  /// Arena Night is the default (DESIGN.md §2).
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isSystem => _themeMode == ThemeMode.system;

  /// Whether the UI is currently dark, resolving `system` via the platform.
  bool get isDark => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark,
      };

  /// Flips between an explicit light and dark choice (leaves `system`).
  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _persist();
  }

  @override
  void didChangePlatformBrightness() {
    // Only the resolved value changed; the stored choice is untouched.
    if (_themeMode == ThemeMode.system) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode? _decode(String? value) => switch (value) {
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = _decode(prefs.getString(_prefsKey));
      if (stored != null && stored != _themeMode) {
        _themeMode = stored;
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
      await prefs.setString(_prefsKey, _encode(_themeMode));
    } catch (e) {
      debugPrint('ThemeProvider: could not persist theme: $e');
    }
  }
}
