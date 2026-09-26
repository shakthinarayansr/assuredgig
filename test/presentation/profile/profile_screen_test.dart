import 'package:assuredgig/core/l10n/locale_controller.dart';
import 'package:assuredgig/core/theme/app_theme.dart';
import 'package:assuredgig/core/theme/theme_controller.dart';
import 'package:assuredgig/l10n/app_localizations.dart';
import 'package:assuredgig/presentation/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The profile screen's two switches: both rebuild in place, and both survive
/// a relaunch.
void main() {
  late ThemeController theme;
  late LocaleController locale;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await GetIt.I.reset();
    theme = await ThemeController.restore();
    locale = await LocaleController.restore();
    GetIt.I
      ..registerSingleton<ThemeController>(theme)
      ..registerSingleton<LocaleController>(locale);
  });

  // Mirrors AssuredGigApp: the MaterialApp listens to both controllers.
  Widget app() => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[theme, locale]),
    builder: (context, _) => MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      locale: locale.locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const ProfileScreen(),
    ),
  );

  Brightness brightnessOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(ProfileScreen))).brightness;

  testWidgets('follows the phone until the Partner picks', (tester) async {
    await tester.pumpWidget(app());
    expect(theme.mode, ThemeMode.system);
    expect(find.text('Same as phone'), findsOneWidget);
  });

  testWidgets('switching to dark rebuilds in place and persists', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(theme.mode, ThemeMode.dark);
    expect(brightnessOf(tester), Brightness.dark);

    final restored = await ThemeController.restore();
    expect(restored.mode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.light);
  });

  testWidgets('switching language relabels the screen and persists', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();

    expect(locale.locale.languageCode, 'ta');
    expect(find.text('சுயவிவரம்'), findsOneWidget);
    // Each language stays findable in its own script.
    expect(find.text('English'), findsOneWidget);

    final restored = await LocaleController.restore();
    expect(restored.locale.languageCode, 'ta');
  });

  testWidgets('Tamil at large text scale does not overflow', (tester) async {
    await locale.setLocale(const Locale('ta'));
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: app(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
