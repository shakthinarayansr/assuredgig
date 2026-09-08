import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the Partner's chosen language.
///
/// Two obligations from TRD §11 (AUTH-01, AUTH-03) shape this class:
///
///   * the choice is **restored before first render**, so the app never flashes
///     English at a Tamil-reading Partner — see [restore], which `main` awaits
///     before `runApp`;
///   * changing it is a **runtime rebuild, not a restart**. Nothing here tears
///     down state, so an in-progress form or a queued outbox row survives a
///     language switch untouched.
///
/// Locale is not sensitive, so it lives in shared preferences. Tokens do not —
/// those go to `flutter_secure_storage` (NFR-05).
class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._locale);

  static const String _storageKey = 'app.locale';

  /// English is the default; Tamil is selectable. Order is the order shown in
  /// the picker.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  static const Locale fallbackLocale = Locale('en');

  final SharedPreferencesAsync _prefs;
  Locale _locale;

  Locale get locale => _locale;

  /// Reads the stored choice. Call and await this before `runApp`.
  static Future<LocaleController> restore() async {
    final prefs = SharedPreferencesAsync();
    final stored = await prefs.getString(_storageKey);
    return LocaleController._(prefs, _parse(stored) ?? fallbackLocale);
  }

  /// Switches language and persists the choice. Safe to call mid-session.
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale) || locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _prefs.setString(_storageKey, locale.languageCode);
  }

  static bool _isSupported(Locale locale) => supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  static Locale? _parse(String? languageCode) {
    if (languageCode == null) return null;
    for (final supported in supportedLocales) {
      if (supported.languageCode == languageCode) return supported;
    }
    return null;
  }
}
