import 'package:go_router/go_router.dart';

import '../core/l10n/locale_controller.dart';
import '../domain/usecases/verify_otp.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/login/language_screen.dart';
import '../presentation/login/login_screen.dart';
import 'di.dart';

/// Route names, referenced rather than typed as literals at call sites so a
/// notification deep link and a screen push cannot drift apart (TRD §10).
abstract final class Routes {
  static const String home = '/';

  /// S-01. The first screen on a fresh install, before anything else (AUTH-01).
  static const String language = '/language';

  /// S-02 and S-03 — number entry and code entry, under one bloc.
  static const String login = '/login';
}

/// The router.
///
/// Notification deep links resolve through here to the exact screen, so paths
/// are part of the app's contract with the backend's push payloads — changing
/// one is a breaking change, not a refactor.
GoRouter buildRouter() {
  final localeController = getIt<LocaleController>();

  return GoRouter(
    initialLocation: localeController.hasChosenLanguage
        ? Routes.login
        : Routes.language,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.language,
        builder: (context, state) =>
            LanguageScreen(onSelected: () => context.go(Routes.login)),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => LoginScreen(
          // Where each destination leads is a routing decision, kept here so
          // the screen does not have to know what comes after it.
          //
          // All three currently land on the placeholder home: the onboarding
          // steps (name, photo, roles, area, availability) and the vetting
          // waiting screen are the next slice of the canvas, and neither
          // exists yet. The destination is already correct — only the screens
          // it points at are missing.
          onAuthenticated: (destination) => switch (destination) {
            AuthenticatedDestination.ready ||
            AuthenticatedDestination.onboarding ||
            AuthenticatedDestination.pendingVetting => context.go(Routes.home),
          },
        ),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
