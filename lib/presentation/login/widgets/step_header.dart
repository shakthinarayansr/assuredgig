import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Back arrow, step counter, and the 3 dp full-bleed progress rule.
///
/// One line of progress for the whole of onboarding, rather than a per-screen
/// indicator: the Partner's question is "how much more of this is there", and
/// a bar that resets every screen answers the wrong one.
class StepHeader extends StatelessWidget {
  const StepHeader({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    super.key,
  });

  final int step;
  final int totalSteps;

  /// Null hides the arrow but keeps the counter aligned — used while a request
  /// is in flight, where going back would strand a half-finished call.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            children: <Widget>[
              // 44 dp of visible circle inside a 48 dp touch target (NFR-06).
              SizedBox(
                width: 48,
                height: 48,
                child: onBack == null
                    ? null
                    : IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, size: 24),
                        color: AppTokens.ink,
                        tooltip: l10n.commonBack,
                      ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.stepOf(step, totalSteps),
                  style: AppTokens.eyebrow,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: AppTokens.strokeProgress,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: step,
                child: const ColoredBox(color: AppTokens.accent),
              ),
              Expanded(
                flex: totalSteps - step,
                child: const ColoredBox(color: AppTokens.hairline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
