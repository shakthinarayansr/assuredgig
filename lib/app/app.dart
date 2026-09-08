import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/brand.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'di.dart';
import 'router.dart';

class AssuredGigApp extends StatefulWidget {
  const AssuredGigApp({super.key});

  @override
  State<AssuredGigApp> createState() => _AssuredGigAppState();
}

class _AssuredGigAppState extends State<AssuredGigApp> {
  late final GoRouter _router = buildRouter();
  late final LocaleController _localeController = getIt<LocaleController>();

  @override
  Widget build(BuildContext context) {
    // Listening here — above the router, below nothing — is what makes a
    // language switch a rebuild rather than a restart (AUTH-03). No state is
    // disposed, so nothing queued or half-typed is lost.
    return ListenableBuilder(
      listenable: _localeController,
      builder: (context, _) => MaterialApp.router(
        title: Brand.name,
        onGenerateTitle: (context) => Brand.name,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
        locale: _localeController.locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
      ),
    );
  }
}
