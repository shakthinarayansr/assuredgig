import 'package:assuredgig/core/theme/app_theme.dart';
import 'package:assuredgig/domain/entities/shift_record.dart';
import 'package:assuredgig/l10n/app_localizations.dart';
import 'package:assuredgig/presentation/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final List<ShiftRecord> _records = <ShiftRecord>[
  ShiftRecord(
    id: 'a',
    roleLabel: 'Store helper',
    venueName: 'Anand Textiles',
    startsAt: DateTime(2026, 9, 20, 9),
    endsAt: DateTime(2026, 9, 20, 17),
    outcome: ShiftOutcome.completed,
    payPaise: 80000,
  ),
  ShiftRecord(
    id: 'b',
    roleLabel: 'Billing counter',
    startsAt: DateTime(2026, 9, 18, 10),
    endsAt: DateTime(2026, 9, 18, 14, 30),
    outcome: ShiftOutcome.completed,
    payPaise: 45050,
  ),
  ShiftRecord(
    id: 'c',
    roleLabel: 'Store helper',
    startsAt: DateTime(2026, 9, 15, 9),
    endsAt: DateTime(2026, 9, 15, 17),
    outcome: ShiftOutcome.noShow,
    noShowReason: 'No check-in recorded',
  ),
];

Widget _app(List<ShiftRecord> records, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(body: HistoryScreen(records: records)),
    );

void main() {
  testWidgets('empty: says what will appear, no zero total', (tester) async {
    await tester.pumpWidget(_app(const <ShiftRecord>[]));
    await tester.pumpAndSettle();

    expect(find.text('No past shifts yet'), findsOneWidget);
    expect(find.text('Earned so far'), findsNothing);
  });

  testWidgets('earned total counts completed shifts only', (tester) async {
    await tester.pumpWidget(_app(_records));
    await tester.pumpAndSettle();

    expect(find.text('Earned so far'), findsOneWidget);
    // 800.00 + 450.50; the no-show adds nothing.
    expect(find.text('₹1,250.50'), findsOneWidget);
    expect(find.text('2 shifts completed'), findsOneWidget);
    expect(find.text('₹800'), findsOneWidget);
    expect(find.text('₹450.50'), findsOneWidget);
  });

  testWidgets('each shift shows date, role, venue, times and hours', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_records));
    await tester.pumpAndSettle();

    expect(find.text('Sun, Sep 20'), findsOneWidget);
    expect(find.text('Anand Textiles'), findsOneWidget);
    // Built with the same formatter: intl's spacing before AM/PM is a
    // narrow no-break space, not a plain one.
    String at(int h, [int m = 0]) =>
        DateFormat.jm('en').format(DateTime(2026, 1, 1, h, m));
    // The completed shift and the no-show both ran 9 to 5.
    expect(find.text('${at(9)} – ${at(17)} · 8 hrs'), findsNWidgets(2));
    expect(find.text('${at(10)} – ${at(14, 30)} · 4.5 hrs'), findsOneWidget);
  });

  testWidgets('a no-show shows the recorded reason, and no pay', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_records));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Marked absent'), 200);

    expect(find.text('Marked absent'), findsOneWidget);
    expect(find.text('No check-in recorded'), findsOneWidget);
  });

  testWidgets('Tamil renders without overflow', (tester) async {
    await tester.pumpWidget(_app(_records, locale: const Locale('ta')));
    await tester.pumpAndSettle();

    expect(find.text('இதுவரை சம்பாதித்தது'), findsOneWidget);
    expect(find.text('2 வேலைகள் முடிந்தன'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
