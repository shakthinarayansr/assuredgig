import 'package:flutter/painting.dart';

/// Shape, target and type tokens from the **Onboarding v2 restyle** canvas.
///
/// **No colour lives here.** Colour comes from `AppPalette` (26 Sep 2026 —
/// see `ai_tools/memory/2026-09-26-app-palette-supersedes-prd-9.md`), read
/// through `AppPalette.of(context)` so it follows the Partner's light / dark
/// choice. The text styles below therefore carry no colour either: a call site
/// adds one with `copyWith(color: palette.text)` and friends.
///
/// Rules the canvas states outright and this file encodes:
///   * depth is a 1 px hairline, never a shadow — `elevation: none in-app`;
///   * selection is a **fill**, not a heavier border, because fill survives a
///     scratched screen in sunlight;
///   * the language screen is dark whatever the theme — it is a moment, not a
///     form.
abstract final class AppTokens {
  // ---- Shape --------------------------------------------------------------

  static const double radiusPill = 999;
  static const double radiusCell = 12;
  static const double radiusField = 14;
  static const double radiusCard = 16;
  static const double radiusLanguage = 22;
  static const double radiusSheet = 24;

  static const double strokeHairline = 1;
  static const double strokeProgress = 3;

  // ---- Targets ------------------------------------------------------------
  //
  // Every one of these is a *minimum*, never a fixed height: Tamil runs 30–50%
  // longer and taller than the English source (NFR-04), and a fixed height is
  // how that becomes a clipped word.

  /// The canvas floor. NFR-06 sets 48 — [AppTheme.minTapTarget] still governs
  /// Material widgets, and nothing here goes below it except icon buttons,
  /// which get 44 of visible circle inside a 48 dp touch area.
  static const double targetMin = 44;
  static const double targetCta = 60;
  static const double targetRoleRow = 76;
  static const double targetGridCell = 48;
  static const double targetKey = 58;
  static const double targetOtpBox = 68;

  // ---- Type ---------------------------------------------------------------
  //
  // ⚠ None of these faces are bundled yet. Flutter falls back to the platform
  // font when a family is missing, so the app renders correctly but not in the
  // designed type. Add the assets (General Sans is Fontshare, not Google) and
  // mind the 25 MB APK budget — see the TODO in `app_theme.dart`, which has the
  // same gap for Poppins/Anek.

  static const String latinFamily = 'General Sans';

  /// Tamil never falls back to the Latin face: Anek Tamil / Noto Sans Tamil is
  /// what makes the script render rather than tofu.
  static const String tamilFamily = 'Noto Sans Tamil';

  /// **Labels only** — step counters, field names, grid headers. Never body,
  /// and never Tamil (the canvas says so explicitly, and mono has no Tamil).
  static const String monoFamily = 'JetBrains Mono';

  /// 32 · w600 · -3.5% — the finish screen.
  static const TextStyle finish = TextStyle(
    fontFamily: latinFamily,
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.12,
  );

  /// 29 · w600 · -3% — the question at the top of a form screen.
  static const TextStyle question = TextStyle(
    fontFamily: latinFamily,
    fontSize: 29,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.87,
  );

  /// 34 · w600 — the language screen, which is a moment rather than a form.
  static const TextStyle display = TextStyle(
    fontFamily: latinFamily,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.02,
  );

  /// 17 · w600 — every pill action.
  static const TextStyle button = TextStyle(
    fontFamily: latinFamily,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// 17 · w500 — a selectable row.
  static const TextStyle rowLabel = TextStyle(
    fontFamily: latinFamily,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.17,
  );

  /// 16 · w400 — body copy. The floor for anything a Partner reads to act.
  static const TextStyle body = TextStyle(
    fontFamily: latinFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// 14 · w400/w500 — the hint under a field.
  static const TextStyle hint = TextStyle(
    fontFamily: latinFamily,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// 11 · w500 · +14% · uppercase mono — step counters and field names.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.54,
  );

  /// 30 · w500 — the digits being typed on the phone screen.
  static const TextStyle digits = TextStyle(
    fontFamily: latinFamily,
    fontSize: 30,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  /// 25 · w500 — a key on the number pad.
  static const TextStyle key = TextStyle(
    fontFamily: latinFamily,
    fontSize: 25,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  /// 28 · w500 — one digit in an OTP box.
  static const TextStyle otpDigit = TextStyle(
    fontFamily: latinFamily,
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w500,
  );
}
