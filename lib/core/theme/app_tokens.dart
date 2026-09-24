import 'package:flutter/widgets.dart';

/// The tokens from the **Onboarding v2 restyle** canvas.
///
/// ⚠ **These conflict with `AppTheme` and with PRD §9.** PRD §9 specifies an
/// amber-forward palette (ink `#0E2F2B`, teal, mint, amber, ice) with Poppins
/// and Anek. The v2 canvas replaces that with a single blue accent on a
/// near-white ground. Both cannot be the design system.
///
/// This file exists so the login flow can match the canvas exactly without
/// silently rewriting the global theme underneath every other screen. Whichever
/// way that conflict resolves, it resolves in one place: promote these into
/// `AppTheme` and delete this file, or delete these and restyle the canvas.
/// See `ai_tools/proposals/2026-09-09-v2-palette-supersedes-prd-9.md`.
///
/// Rules the canvas states outright and this file encodes:
///   * depth is a 1 px hairline, never a shadow — `elevation: none in-app`;
///   * selection is a **fill**, not a heavier border, because fill survives a
///     scratched screen in sunlight;
///   * form screens stay near-white; only language and the finish go dark.
abstract final class AppTokens {
  // ---- Colour -------------------------------------------------------------

  static const Color accent = Color(0xFF0B6BFF);
  static const Color accentPress = Color(0xFF0752C4);

  /// Load-bearing text. 6.4:1 and up on [ground].
  static const Color ink = Color(0xFF0D0F12);
  static const Color inkMuted = Color(0xFF5B6167);

  /// **Label-only, 11–14 px.** 3.5:1 — above the 3:1 floor for non-essential
  /// text and below the 4.5:1 one for everything else. Never use it for a
  /// sentence a Partner has to read to act.
  static const Color inkFaint = Color(0xFF8A9099);

  static const Color ground = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sunken = Color(0xFFEDEFF3);
  static const Color hairline = Color(0xFFE4E6EA);
  static const Color hairlineStrong = Color(0xFFD6DAE0);

  static const Color error = Color(0xFFE5484D);

  /// Error *text*. The lighter [error] is for rules and borders only.
  static const Color errorInk = Color(0xFFC4292E);

  /// Only ever on ink — the notice bar's icon.
  static const Color notice = Color(0xFFFFC53D);

  // Dark bookends: the language screen and the finish screen.
  static const Color darkGround = Color(0xFF0D0F12);
  static const Color darkSurface = Color(0xFF15181D);
  static const Color darkHairline = Color(0xFF2A2F37);
  static const Color darkInk = Color(0xFFFFFFFF);
  static const Color darkInkMuted = Color(0xFF9AA1AB);
  static const Color darkInkFaint = Color(0xFF6E757E);

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
    color: ink,
  );

  /// 29 · w600 · -3% — the question at the top of a form screen.
  static const TextStyle question = TextStyle(
    fontFamily: latinFamily,
    fontSize: 29,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.87,
    color: ink,
  );

  /// 34 · w600 — the language screen, which is a moment rather than a form.
  static const TextStyle display = TextStyle(
    fontFamily: latinFamily,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.02,
    color: darkInk,
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
    color: ink,
  );

  /// 16 · w400 — body copy. The floor for anything a Partner reads to act.
  static const TextStyle body = TextStyle(
    fontFamily: latinFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: inkMuted,
  );

  /// 14 · w400/w500 — the hint under a field.
  static const TextStyle hint = TextStyle(
    fontFamily: latinFamily,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: inkFaint,
  );

  /// 11 · w500 · +14% · uppercase mono — step counters and field names.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.54,
    color: inkFaint,
  );

  /// 30 · w500 — the digits being typed on the phone screen.
  static const TextStyle digits = TextStyle(
    fontFamily: latinFamily,
    fontSize: 30,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: ink,
  );

  /// 25 · w500 — a key on the number pad.
  static const TextStyle key = TextStyle(
    fontFamily: latinFamily,
    fontSize: 25,
    height: 1,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  /// 28 · w500 — one digit in an OTP box.
  static const TextStyle otpDigit = TextStyle(
    fontFamily: latinFamily,
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w500,
    color: ink,
  );
}
