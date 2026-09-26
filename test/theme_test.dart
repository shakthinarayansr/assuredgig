import 'dart:math' as math;

import 'package:assuredgig/core/theme/app_palette.dart';
import 'package:assuredgig/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards NFR-06 at the theme level, so a screen cannot quietly ship a target
/// too small for a Partner tapping with a thumb, outdoors, in a hurry — and
/// the palette's own rule that every text/background pair is at least 4.5:1.
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

      test('carries the palette extension', () {
        expect(theme.value.extension<AppPalette>(), isNotNull);
      });

      test('errors use danger, never the SOS red', () {
        final p = theme.value.extension<AppPalette>()!;
        expect(theme.value.colorScheme.error, p.danger);
        expect(theme.value.colorScheme.error, isNot(p.sos));
      });
    });
  }

  for (final palette in <String, AppPalette>{
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  }.entries) {
    test('${palette.key} palette: text pairs are at least 4.5:1', () {
      final p = palette.value;
      final surfaces = <String, Color>{
        'bg': p.bg,
        'surface': p.surface,
        'surfaceAlt': p.surfaceAlt,
        'sky': p.sky,
        'aqua': p.aqua,
        'mint': p.mint,
        'lilac': p.lilac,
      };
      final pairs = <String, (Color, Color)>{
        for (final s in surfaces.entries) ...<String, (Color, Color)>{
          'text on ${s.key}': (p.text, s.value),
          'textMuted on ${s.key}': (p.textMuted, s.value),
        },
        'textDisabled on bg': (p.textDisabled, p.bg),
        'primary on bg': (p.primary, p.bg),
        'onPrimary on primary': (p.onPrimary, p.primary),
        'success on successSurface': (p.success, p.successSurface),
        'warning on warningSurface': (p.warning, p.warningSurface),
        'danger on dangerSurface': (p.danger, p.dangerSurface),
        'onSos on sos': (p.onSos, p.sos),
        // Pairs the login flow introduces: the disabled pill's label, which
        // says what is missing and so must be read, and the slow-line banner.
        'textMuted on divider': (p.textMuted, p.divider),
        'text on warningSurface': (p.text, p.warningSurface),
      };

      for (final pair in pairs.entries) {
        final (fg, bg) = pair.value;
        expect(
          _contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '${pair.key} is below 4.5:1',
        );
      }
    });
  }

  test('shift card text pairs are at least 4.5:1', () {
    expect(
      _contrast(ShiftCardColors.bandText, ShiftCardColors.band),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(ShiftCardColors.text, ShiftCardColors.body),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(ShiftCardColors.textMuted, ShiftCardColors.body),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(ShiftCardColors.chipText, ShiftCardColors.chipBg),
      greaterThanOrEqualTo(4.5),
    );
  });
}

/// WCAG 2.x contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
