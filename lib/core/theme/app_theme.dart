import 'package:flutter/material.dart';

/// The design system from PRD §9, and the layout rules that keep it usable.
///
/// Two constraints are encoded here rather than left to each screen, because
/// both are the kind that gets forgotten exactly once and then ships:
///
///   * every interactive target is at least 48 dp (NFR-06);
///   * nothing constrains text to a fixed height or a single line, because
///     Indian scripts run 30–50% longer and taller than the English source
///     (NFR-04) — the single most common cause of layout breakage here.
abstract final class AppTheme {
  /// Minimum interactive target, per NFR-06.
  static const double minTapTarget = 48;

  // PRD §9. These five are the whole palette; do not introduce a sixth without
  // changing that document first.
  static const Color ink = Color(0xFF0E2F2B);
  static const Color teal = Color(0xFF0F6E56);
  static const Color mint = Color(0xFF1D9E75);
  static const Color amber = Color(0xFFEF9F27);
  static const Color ice = Color(0xFFCFE0DB);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// AssuredGig is **amber-forward** (PRD §9): amber carries pay figures and
  /// primary actions, teal recedes to structure. That is the opposite weighting
  /// to the company-facing brand, so do not "fix" it by promoting teal.
  static ColorScheme _colors(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: amber,
      onPrimary: ink,
      primaryContainer: isDark
          ? const Color(0xFF6B4610)
          : const Color(0xFFFDEBCC),
      onPrimaryContainer: isDark ? const Color(0xFFFDEBCC) : ink,
      secondary: teal,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF0A4335) : ice,
      onSecondaryContainer: isDark ? ice : ink,
      tertiary: mint,
      onTertiary: isDark ? ink : Colors.white,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: isDark ? ink : Colors.white,
      onSurface: isDark ? ice : ink,
      surfaceContainerHighest: isDark ? const Color(0xFF1A423D) : ice,
      onSurfaceVariant: isDark ? ice : const Color(0xFF3F544F),
      outline: isDark ? const Color(0xFF5C7C75) : const Color(0xFF8FAAA3),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final colorScheme = _colors(brightness);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,

      // TODO(fonts): PRD §9 specifies Poppins for display and the Anek family
      // for body and all Indian scripts. Neither is bundled yet — Anek Tamil in
      // particular is what makes Tamil render correctly rather than fall back.
      // Add them as assets (not a network font loader) before any Tamil
      // walkthrough, and mind the 25 MB APK budget when subsetting.

      // Applies the 48 dp floor to every Material tap target in the app rather
      // than relying on each screen to remember it.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // Deliberately no maxLines: a primary action must wrap rather than
          // ellipsise when translated.
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
        ),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// The pay figure on an offer card — the largest element and the first thing
  /// a worker looks for (PRD §4.2: the decision order is pay, distance, date).
  ///
  /// Tabular lining numerals so amounts align down a list instead of jittering.
  static TextStyle payFigure(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.amber,
        fontFeatures: const <FontFeature>[
          FontFeature.tabularFigures(),
          FontFeature.liningFigures(),
        ],
      );
}
