import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// An icon, a heading and a sentence saying what will appear here and when.
///
/// An empty list is a state, not an absence: it says what the Partner is
/// waiting for, so a new account does not read as a broken one.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.sky,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: palette.primary),
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
