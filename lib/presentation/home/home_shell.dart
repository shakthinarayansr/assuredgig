import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/entities/auth_failure.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/partner_header_cubit.dart';
import 'widgets/partner_header.dart';

/// The app's frame once signed in: the Partner in the app bar, the tabs at the
/// bottom (PRD §3).
///
/// Shifts is the first tab and where the app lands — there is no dashboard in
/// front of it, because a summary would push expiring offers below a fold.
///
/// The shell owns no navigation itself. Which tab is showing, and what each
/// tap leads to, belong to the router; this widget only draws them.
class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onOpenProfile,
    required this.onSessionExpired,
    required this.child,
    super.key,
  });

  /// Index into [HomeTab.values].
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onOpenProfile;

  /// The server refused the token. Not an error to show — a trip to login.
  final VoidCallback onSessionExpired;

  /// The current tab's screen.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = AppPalette.of(context);

    return BlocProvider<PartnerHeaderCubit>(
      create: (_) => getIt<PartnerHeaderCubit>()..load(),
      child: BlocConsumer<PartnerHeaderCubit, PartnerHeaderState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure &&
            current.failure == AuthFailure.sessionExpired,
        listener: (context, state) => onSessionExpired(),
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            titleSpacing: 8,
            title: Align(
              alignment: AlignmentDirectional.centerStart,
              child: PartnerHeader(name: state.name, onTap: onOpenProfile),
            ),
            // SOS goes in `actions` — persistent, one tap from every screen
            // (SAFE-01, NFR-10). Held until CLAUDE.md §7's location question
            // is resolved; do not put anything else here that could crowd it.
          ),
          body: child,
          bottomNavigationBar: DecoratedBox(
            // Hairline, not shadow — depth in this app is a line.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.divider)),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onTabSelected,
              backgroundColor: palette.surface,
              indicatorColor: palette.sky,
              surfaceTintColor: Colors.transparent,
              // Icons always carry their label: an icon alone asks a
              // low-literacy reader to guess.
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: <Widget>[
                for (final tab in HomeTab.values)
                  switch (tab) {
                    HomeTab.shifts => NavigationDestination(
                      icon: const Icon(Icons.work_outline),
                      selectedIcon: Icon(Icons.work, color: palette.primary),
                      label: l10n.navShifts,
                    ),
                    HomeTab.history => NavigationDestination(
                      icon: const Icon(Icons.history),
                      selectedIcon: Icon(Icons.history, color: palette.primary),
                      label: l10n.navHistory,
                    ),
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom tabs, in order. The router's shell branches follow this order.
///
/// Profile joins as the third tab when it has more to hold than settings; until
/// then it opens from the avatar.
enum HomeTab { shifts, history }
