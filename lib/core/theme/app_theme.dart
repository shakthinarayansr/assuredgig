import 'package:flutter/material.dart';

/// App theme.
///
/// Built for the real pilot device and the real Partner: a 2 GB RAM entry-level
/// Android phone, held by someone who may be reading Tamil at a large system
/// text scale. Two rules follow from that and are encoded here rather than left
/// to each screen (TRD §11, NFR-06):
///
///   * every interactive target is at least 48 dp;
///   * nothing constrains text to a fixed height or a single line, because
///     Tamil renders materially longer than English.
abstract final class AppTheme {
  /// Minimum interactive target, per NFR-06.
  static const double minTapTarget = 48;

  static const Color _seed = Color(0xFF1B5E20);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,

      // Applies the 48 dp floor to every Material tap target in the app rather
      // than relying on each screen to remember it.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // Deliberately unset maxLines: a primary action must be allowed to
          // wrap rather than ellipsise when translated.
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
}
