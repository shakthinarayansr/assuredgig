import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

/// S-11 — the Shifts tab: offers, upcoming bookings and the active shift, and
/// the screen the app lands on.
///
/// Only the empty state exists yet. Offers need the shifts endpoint and the
/// cache-first read from build phase 4; the other S-11 states (offers only,
/// bookings only, mixed, loading, offline) arrive with them.
class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          // Centred when it fits, scrollable when Tamil or a large font size
          // makes it taller than the screen.
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: EmptyState(
              icon: Icons.work_outline,
              title: l10n.shiftsEmptyTitle,
              body: l10n.shiftsEmptyBody,
            ),
          ),
        ),
      ),
    );
  }
}
