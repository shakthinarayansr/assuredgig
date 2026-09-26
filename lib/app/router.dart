import 'package:go_router/go_router.dart';

import '../core/l10n/locale_controller.dart';
import '../domain/entities/shift_record.dart';
import '../domain/usecases/verify_otp.dart';
import '../presentation/history/history_screen.dart';
import '../presentation/home/home_shell.dart';
import '../presentation/login/language_screen.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/shifts/shifts_screen.dart';
import 'di.dart';

/// Route names, referenced rather than typed as literals at call sites so a
/// notification deep link and a screen push cannot drift apart (TRD §10).
abstract final class Routes {
  /// Where a signed-in Partner lands. Always the Shifts tab — there is no
  /// dashboard in front of it (PRD §3).
  static const String home = shifts;

  /// S-11 — first bottom tab.
  static const String shifts = '/shifts';

  /// S-26 — second bottom tab.
  static const String history = '/history';

  /// S-01. The first screen on a fresh install, before anything else (AUTH-01).
  static const String language = '/language';

  /// S-02 and S-03 — number entry and code entry, under one bloc.
  static const String login = '/login';

  /// S-21 — profile home, with appearance and language (S-29). Pushed over
  /// the tabs from the avatar in the app bar, so back returns to the tab the
  /// Partner came from.
  static const String profile = '/profile';
}

/// The router.
///
/// Notification deep links resolve through here to the exact screen, so paths
/// are part of the app's contract with the backend's push payloads — changing
/// one is a breaking change, not a refactor.
///
/// [initialLocation] is for tests; the app decides it from the stored
/// language choice.
GoRouter buildRouter({String? initialLocation}) {
  final localeController = getIt<LocaleController>();

  return GoRouter(
    initialLocation:
        initialLocation ??
        (localeController.hasChosenLanguage ? Routes.login : Routes.language),
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
      // The tabs. `indexedStack` keeps each tab's screen alive while another
      // is showing, so switching back does not lose a scroll position or
      // refetch what was already on screen.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(
          currentIndex: shell.currentIndex,
          // Tapping the tab you are already on returns it to its root.
          onTabSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          onOpenProfile: () => context.push(Routes.profile),
          onSessionExpired: () => context.go(Routes.login),
          child: shell,
        ),
        // One branch per HomeTab, in the same order.
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.shifts,
                builder: (context, state) => const ShiftsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.history,
                // No history endpoint yet — see HistoryScreen.
                builder: (context, state) =>
                    const HistoryScreen(records: <ShiftRecord>[]),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
