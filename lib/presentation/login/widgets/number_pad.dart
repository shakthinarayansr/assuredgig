import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// The on-screen pad the phone and code steps use instead of the system
/// keyboard.
///
/// Deliberate: the system IME on a budget Android is small, covers the field,
/// and opens on whichever layout the phone was last left in. A fixed pad of
/// 58 dp keys is bigger than any soft keyboard's, cannot show the wrong
/// alphabet, and puts the digits in the same place every time — which matters
/// most for the Partners who type least.
class NumberPad extends StatelessWidget {
  const NumberPad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final row in const <List<String>>[
            <String>['1', '2', '3'],
            <String>['4', '5', '6'],
            <String>['7', '8', '9'],
            <String>['', '0', 'del'],
          ])
            Row(
              children: <Widget>[
                for (final cell in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: switch (cell) {
                        // The dead cell keeps 0 centred and backspace under the
                        // thumb, where the system keyboard also puts it.
                        '' => const SizedBox(height: AppTokens.targetKey),
                        'del' => _Key(
                          onTap: onBackspace,
                          semanticLabel: l10n.keypadDelete,
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 24,
                            color: AppTokens.inkMuted,
                          ),
                        ),
                        _ => _Key(
                          onTap: () => onDigit(cell),
                          semanticLabel: cell,
                          child: Text(cell, style: AppTokens.key),
                        ),
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.onTap,
    required this.child,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          child: SizedBox(
            height: AppTokens.targetKey,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
