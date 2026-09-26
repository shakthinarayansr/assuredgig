import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the Partner's light / dark choice.
///
/// Shaped like `LocaleController`, for the same reasons:
///
///   * the choice is **restored before first render**, so a Partner who picked
///     dark never gets a white flash at a night shift — see [restore], which
///     DI awaits before `runApp`;
///   * changing it is a **runtime rebuild, not a restart**, so nothing queued
///     or half-typed is lost.
///
/// Defaults to following the phone ([ThemeMode.system]) until the Partner
/// picks. Not sensitive, so it lives in shared preferences.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs, this._mode);

  static const String _storageKey = 'app.themeMode';

  /// Order is the order shown in the picker.
  static const List<ThemeMode> options = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  final SharedPreferencesAsync _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the stored choice. Call and await this before `runApp`.
  static Future<ThemeController> restore() async {
    final prefs = SharedPreferencesAsync();
    final stored = await prefs.getString(_storageKey);
    return ThemeController._(prefs, _parse(stored) ?? ThemeMode.system);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_storageKey, mode.name);
  }

  static ThemeMode? _parse(String? stored) {
    for (final mode in options) {
      if (mode.name == stored) return mode;
    }
    return null;
  }
}
