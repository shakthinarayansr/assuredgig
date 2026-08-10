import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/l10n/locale_controller.dart';
import '../../l10n/app_localizations.dart';

/// Placeholder for the real shell.
///
/// It exists so the foundation is demonstrably working end to end — routing,
/// theme, and a language switch that rebuilds without restarting. Delete it
/// when the real screens land.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final localeController = getIt<LocaleController>();

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
            Text(
              l10n.chooseLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final locale in LocaleController.supportedLocales)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: () => localeController.setLocale(locale),
                  child: Text(switch (locale.languageCode) {
                    'ta' => l10n.languageTamil,
                    _ => l10n.languageEnglish,
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
