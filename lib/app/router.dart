import 'package:go_router/go_router.dart';

import '../presentation/home/home_screen.dart';

/// Route names, referenced rather than typed as literals at call sites so a
/// notification deep link and a screen push cannot drift apart (TRD §10).
abstract final class Routes {
  static const String home = '/';
}

/// The router.
///
/// Notification deep links resolve through here to the exact screen, so paths
/// are part of the app's contract with the backend's push payloads — changing
/// one is a breaking change, not a refactor.
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: <RouteBase>[
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
  ],
);
