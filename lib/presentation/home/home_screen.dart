import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';

/// Placeholder for the real shell.
///
/// It exists so the foundation is demonstrably working end to end — routing,
/// theme, and the profile screen's language and appearance switches. Delete it
/// when the Shifts / History / Profile tabs land.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homePlaceholderTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.homePlaceholderBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push(Routes.profile),
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.homeOpenProfile),
            ),
          ],
        ),
      ),
    );
  }
}
