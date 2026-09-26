import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';

/// The dark bar at the top of the screen: a state, not an error.
///
/// The palette's warning pair — amber, as the canvas had it. It is
/// deliberately not red and not a dialog — the app is still working, and a Partner who reads
/// "failed" at a venue with no signal will retry, panic, or leave
/// (CLAUDE.md §2).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return ColoredBox(
      color: p.warningSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 17, color: p.warning),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: AppTokens.latinFamily,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: p.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
