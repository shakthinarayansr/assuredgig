import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// The dark bar at the top of the screen: a state, not an error.
///
/// Ink ground with an amber icon, per the canvas. It is deliberately not red
/// and not a dialog — the app is still working, and a Partner who reads
/// "failed" at a venue with no signal will retry, panic, or leave
/// (CLAUDE.md §2).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTokens.darkGround,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 17, color: AppTokens.notice),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: AppTokens.latinFamily,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8EAEE),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
