import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// The app's light and dark themes, built from [AppPalette].
///
/// This replaces the PRD §9 amber-forward palette — see
/// `ai_tools/memory/2026-09-26-app-palette-supersedes-prd-9.md`. Colours live
/// in `app_palette.dart`; this file only maps them onto Material.
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

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ColorScheme _colors(Brightness brightness, AppPalette p) =>
      ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        primaryContainer: p.sky,
        onPrimaryContainer: p.text,
        secondary: p.primaryPressed,
        onSecondary: p.onPrimary,
        secondaryContainer: p.surfaceAlt,
        onSecondaryContainer: p.text,
        tertiary: p.success,
        onTertiary: p.onPrimary,
        tertiaryContainer: p.successSurface,
        onTertiaryContainer: p.text,
        // Error is `danger`, never `sos` — the red reserved for safety must not
        // turn up on a mistyped field.
        error: p.danger,
        onError: brightness == Brightness.light ? Colors.white : p.bg,
        errorContainer: p.dangerSurface,
        onErrorContainer: p.text,
        surface: p.surface,
        onSurface: p.text,
        surfaceContainerLowest: p.bg,
        surfaceContainerLow: p.surfaceAlt,
        surfaceContainer: p.surfaceAlt,
        surfaceContainerHigh: p.sky,
        surfaceContainerHighest: p.sky,
        onSurfaceVariant: p.textMuted,
        outline: p.divider,
        outlineVariant: p.divider,
        scrim: p.scrim,
        shadow: Colors.transparent,
      );

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final colorScheme = _colors(brightness, p);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[p],
      scaffoldBackgroundColor: p.bg,
      dividerColor: p.divider,
      disabledColor: p.textDisabled,

      // TODO(fonts): neither the Latin display face nor Anek / Noto Sans Tamil
      // is bundled yet — Anek Tamil in particular is what makes Tamil render
      // correctly rather than fall back. Add them as assets (not a network font
      // loader) before any Tamil walkthrough, and mind the 25 MB APK budget
      // when subsetting.

      // Applies the 48 dp floor to every Material tap target in the app rather
      // than relying on each screen to remember it.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      // The app bar and the status bar above it are one band of `statusBar`,
      // so the top of the screen does not split into two colours.
      appBarTheme: AppBarTheme(
        backgroundColor: p.statusBar,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemOverlay(p, brightness),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      // Depth is a hairline, not a shadow.
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.divider),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.divider,
          disabledForegroundColor: p.textDisabled,
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // Deliberately no maxLines: a primary action must wrap rather than
          // ellipsise when translated.
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.divider),
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size(minTapTarget, minTapTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        iconColor: p.textMuted,
        textColor: p.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// The status bar for a screen drawn in [p]. App bars get it from the theme;
  /// a screen with no app bar (login, language) wraps itself in an
  /// `AnnotatedRegion` with this, or the icons can end up dark-on-dark.
  static SystemUiOverlayStyle systemOverlay(
    AppPalette p,
    Brightness brightness,
  ) => SystemUiOverlayStyle(
    statusBarColor: p.statusBar,
    statusBarIconBrightness: brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
    statusBarBrightness: brightness,
  );

  /// The pay figure on an offer card — the largest element and the first thing
  /// a worker looks for (PRD §4.2: the decision order is pay, distance, date).
  ///
  /// Tabular lining numerals so amounts align down a list instead of jittering.
  static TextStyle payFigure(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.of(context).text,
        fontFeatures: const <FontFeature>[
          FontFeature.tabularFigures(),
          FontFeature.liningFigures(),
        ],
      );
}
