import 'package:assuredgig/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards NFR-06 at the theme level, so a screen cannot quietly ship a target
/// too small for a Partner tapping with a thumb, outdoors, in a hurry.
void main() {
  for (final theme in <String, ThemeData>{
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    group('${theme.key} theme', () {
      test('button styles meet the 48 dp minimum target', () {
        final styles = <String, ButtonStyle?>{
          'filled': theme.value.filledButtonTheme.style,
          'outlined': theme.value.outlinedButtonTheme.style,
          'text': theme.value.textButtonTheme.style,
          'icon': theme.value.iconButtonTheme.style,
        };

        for (final entry in styles.entries) {
          final size = entry.value?.minimumSize?.resolve(<WidgetState>{});
          expect(size, isNotNull, reason: '${entry.key} button has no minimum');
          expect(
            size!.height,
            greaterThanOrEqualTo(AppTheme.minTapTarget),
            reason: '${entry.key} button is shorter than 48 dp',
          );
          expect(
            size.width,
            greaterThanOrEqualTo(AppTheme.minTapTarget),
            reason: '${entry.key} button is narrower than 48 dp',
          );
        }
      });

      test('tap targets are padded, not shrink-wrapped', () {
        expect(theme.value.materialTapTargetSize, MaterialTapTargetSize.padded);
      });
    });
  }
}
