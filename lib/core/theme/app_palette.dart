import 'package:flutter/material.dart';

/// The AssuredGig app palette (26 Sep 2026), light and dark.
///
/// Carried on the theme as an extension so a screen reads
/// `AppPalette.of(context).surfaceAlt` and gets the right value for the mode
/// the Partner chose, instead of importing a constant that is only right in
/// one of them.
///
/// Rules the palette states outright, and which every screen must keep:
///
///   * **pastels are surfaces only, never text colour** — [sky], [aqua],
///     [mint] and [lilac] sit behind text, never in it;
///   * **[sos] is reserved for the SOS control and safety escalation only.**
///     Not for errors (that is [danger]), not for emphasis. A red that means
///     "emergency" everywhere means it nowhere;
///   * every text/background pair listed is at least 4.5:1 — `theme_test.dart`
///     fails the build if an edit breaks that;
///   * the shift card is the same in both themes — see [ShiftCardColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.text,
    required this.textMuted,
    required this.textDisabled,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.sky,
    required this.aqua,
    required this.mint,
    required this.lilac,
    required this.divider,
    required this.scrim,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.sos,
    required this.onSos,
    required this.statusBar,
  });

  static const AppPalette light = AppPalette(
    primary: Color(0xFF1976D2),
    primaryPressed: Color(0xFF1565C0),
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF0F2744),
    textMuted: Color(0xFF4A5B75),
    textDisabled: Color(0xFF68768F),
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF6FE),
    sky: Color(0xFFE6F2FD),
    aqua: Color(0xFFD6F1F3),
    mint: Color(0xFFDDF4EA),
    lilac: Color(0xFFECE7FF),
    divider: Color(0xFFD8E6F5),
    scrim: Color(0x800F2744),
    success: Color(0xFF17784F),
    successSurface: Color(0xFFDDF4EA),
    warning: Color(0xFF8A5300),
    warningSurface: Color(0xFFFFF0D6),
    danger: Color(0xFFB3161A),
    dangerSurface: Color(0xFFFDE8E8),
    sos: Color(0xFFC62021),
    onSos: Color(0xFFFFFFFF),
    statusBar: Color(0xFFEEF6FE),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF8FAEFF),
    primaryPressed: Color(0xFFA9C1FF),
    onPrimary: Color(0xFF0E1631),
    text: Color(0xFFE7ECFA),
    textMuted: Color(0xFFA9B3D1),
    textDisabled: Color(0xFF8793B4),
    bg: Color(0xFF0E1631),
    surface: Color(0xFF152044),
    surfaceAlt: Color(0xFF111B3D),
    sky: Color(0xFF17234B),
    aqua: Color(0xFF12323A),
    mint: Color(0xFF13302C),
    lilac: Color(0xFF221F48),
    divider: Color(0xFF25325A),
    scrim: Color(0xB3000000),
    success: Color(0xFF5FD3A0),
    successSurface: Color(0xFF13302C),
    warning: Color(0xFFFFC46B),
    warningSurface: Color(0xFF3A2C10),
    danger: Color(0xFFFF9B9B),
    dangerSurface: Color(0xFF3A1A1E),
    sos: Color(0xFFFF6B6B),
    onSos: Color(0xFF0E1631),
    statusBar: Color(0xFF111B3D),
  );

  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;

  final Color text;
  final Color textMuted;
  final Color textDisabled;

  final Color bg;
  final Color surface;
  final Color surfaceAlt;

  /// Pastel surfaces. Never text.
  final Color sky;
  final Color aqua;
  final Color mint;
  final Color lilac;

  final Color divider;
  final Color scrim;

  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;

  /// SOS and safety escalation only.
  final Color sos;
  final Color onSos;

  /// Behind the Android status bar, and the app bar that meets it.
  final Color statusBar;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith() => this;

  /// Snaps rather than tweens. A theme switch is a deliberate choice, and
  /// half-way colours between two palettes are pairs nobody checked contrast on.
  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// The shift card: white body, blue band — **identical in both themes.**
///
/// It is the object a Partner scans a list for and shows to a supervisor at
/// the gate, so it keeps one look whatever the phone is set to. The one
/// difference is the border: in light mode a hairline separates white card
/// from white page; in dark mode the page already does, so there is none.
abstract final class ShiftCardColors {
  static const Color body = Color(0xFFFFFFFF);
  static const Color band = Color(0xFF1976D2);
  static const Color bandText = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F2744);
  static const Color textMuted = Color(0xFF4A5B75);
  static const Color chipBg = Color(0xFFE6F2FD);
  static const Color chipText = Color(0xFF1565C0);
  static const Color borderLight = Color(0xFFD8E6F5);

  /// Null in dark mode, by design.
  static Color? border(Brightness brightness) =>
      brightness == Brightness.light ? borderLight : null;
}
