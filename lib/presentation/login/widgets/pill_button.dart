import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// How much weight a pill action carries.
enum PillVariant {
  /// Filled accent. One per screen.
  primary,

  /// White with a hairline. The second way out of a screen.
  secondary,

  /// No fill, no border. The way back.
  ghost,
}

/// The canvas's one action shape: a 60 dp pill, full width, radius 999.
///
/// Disabled is a **fill change**, not an opacity change — a greyed-out control
/// on a cheap LCD in sunlight is often just invisible, whereas `#E4E6EA` on
/// `#8A9099` still reads as a control that is not ready yet. The label changes
/// with it ("5 of 10 digits"), so the button says *why* rather than going quiet.
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.icon,
    super.key,
  });

  final String label;

  /// Null disables the button. The label should say what is missing.
  final VoidCallback? onPressed;
  final PillVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final (
      Color background,
      Color foreground,
      Color? border,
    ) = switch (variant) {
      PillVariant.primary when enabled => (
        AppTokens.accent,
        Colors.white,
        null,
      ),
      PillVariant.primary => (AppTokens.hairline, AppTokens.inkFaint, null),
      PillVariant.secondary => (
        AppTokens.surface,
        AppTokens.ink,
        AppTokens.hairlineStrong,
      ),
      PillVariant.ghost => (Colors.transparent, AppTokens.inkMuted, null),
    };

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border, width: AppTokens.strokeHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          // Minimum, not fixed: a Tamil label wraps to two lines rather than
          // being clipped (NFR-04).
          constraints: BoxConstraints(
            minHeight: variant == PillVariant.primary
                ? AppTokens.targetCta
                : 52,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 21, color: foreground),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTokens.button.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
