import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/shift_record.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../common/money.dart';

/// S-26 — the History tab: past shifts and what they paid (HIST-02), with
/// no-shows shown alongside and their recorded reason (HIST-04).
///
/// Takes its records rather than fetching them. There is no history endpoint
/// yet, so the router passes an empty list and the empty state is what ships;
/// the populated layout is exercised by its widget test. When the endpoint
/// lands, a bloc reads it cache-first and feeds this.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.records, super.key});

  /// Newest first, as the server orders them.
  final List<ShiftRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (records.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: EmptyState(
                icon: Icons.history,
                title: l10n.historyEmptyTitle,
                body: l10n.historyEmptyBody,
              ),
            ),
          ),
        ),
      );
    }

    final completed = records.where((r) => r.outcome == ShiftOutcome.completed);
    // Summed here for display only. When the endpoint exists, prefer a total
    // the server sends — it knows about adjustments this list does not.
    final earnedPaise = completed.fold<int>(
      0,
      (sum, r) => sum + (r.payPaise ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _EarningsSummary(
          earnedPaise: earnedPaise,
          completedCount: completed.length,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Semantics(
            header: true,
            child: Text(
              l10n.historyPastShiftsHeading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.of(context).text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (final record in records) ...<Widget>[
          _RecordCard(record: record),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Money earned, first and largest — it is the number a Partner opens this tab
/// to find.
class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({
    required this.earnedPaise,
    required this.completedCount,
  });

  final int earnedPaise;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.mint,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.historyEarnedLabel,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupees(context, earnedPaise),
            style: AppTheme.payFigure(context),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.historyShiftsCompleted(completedCount),
            style: textTheme.bodyMedium?.copyWith(color: palette.text),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final ShiftRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale);
    final hours = NumberFormat(
      '0.#',
      locale,
    ).format(record.duration.inMinutes / 60);
    final isNoShow = record.outcome == ShiftOutcome.noShow;
    final pay = record.payPaise;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        DateFormat.MMMEd(locale).format(record.startsAt),
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.roleLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (record.venueName case final venue?) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          venue,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.text,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!isNoShow && pay != null)
                  Text(
                    formatRupees(context, pay),
                    style: textTheme.titleLarge?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.historyShiftTime(
                time.format(record.startsAt),
                time.format(record.endsAt),
                hours,
              ),
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
            if (isNoShow) ...<Widget>[
              const SizedBox(height: 12),
              _NoShowNote(reason: record.noShowReason),
            ],
          ],
        ),
      ),
    );
  }
}

/// A no-show is stated, not shouted: warning colours, not danger, and the
/// reason ops recorded. Disputing it (S-28) hangs off this when it is built.
class _NoShowNote extends StatelessWidget {
  const _NoShowNote({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warningSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCell),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.historyOutcomeNoShow,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (reason case final reason?) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              reason,
              style: textTheme.bodyMedium?.copyWith(color: palette.text),
            ),
          ],
        ],
      ),
    );
  }
}
