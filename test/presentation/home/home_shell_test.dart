import 'package:assuredgig/app/router.dart';
import 'package:assuredgig/core/l10n/locale_controller.dart';
import 'package:assuredgig/core/theme/app_theme.dart';
import 'package:assuredgig/core/theme/theme_controller.dart';
import 'package:assuredgig/domain/entities/auth_failure.dart';
import 'package:assuredgig/domain/entities/worker_profile.dart';
import 'package:assuredgig/domain/entities/worker_status.dart';
import 'package:assuredgig/domain/usecases/get_worker_profile.dart';
import 'package:assuredgig/domain/usecases/request_otp.dart';
import 'package:assuredgig/domain/usecases/verify_otp.dart';
import 'package:assuredgig/l10n/app_localizations.dart';
import 'package:assuredgig/presentation/home/bloc/partner_header_cubit.dart';
import 'package:assuredgig/presentation/login/bloc/login_bloc.dart';
import 'package:assuredgig/presentation/login/login_screen.dart';
import 'package:assuredgig/presentation/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeProfile implements GetWorkerProfile {
  String? name = 'Kavya Raman';
  AuthFailure? fail;

  @override
  Future<WorkerProfile> call() async {
    if (fail != null) throw AuthException(fail!);
    return WorkerProfile(
      id: 'w1',
      phone: '+910000000000',
      name: name,
      status: WorkerStatus.active,
      languageCode: 'en',
      roles: const <String>[],
      travelDistanceKm: 5,
      profileComplete: true,
      missingFields: const <ProfileRequirement>[],
      hasAvailability: false,
    );
  }
}

class _UnusedRequest implements RequestOtp {
  @override
  Future<OtpChallenge> call({required String phone}) =>
      throw UnimplementedError();
}

class _UnusedVerify implements VerifyOtp {
  @override
  Future<AuthenticatedDestination> call({
    required String phone,
    required String code,
  }) => throw UnimplementedError();
}

/// The signed-in frame, driven through the real router: where it lands, the
/// tabs, and the avatar's way to the profile.
void main() {
  late _FakeProfile profile;
  late GoRouter router;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await GetIt.I.reset();
    profile = _FakeProfile();
    GetIt.I
      ..registerSingleton<ThemeController>(await ThemeController.restore())
      ..registerSingleton<LocaleController>(await LocaleController.restore())
      ..registerFactory<PartnerHeaderCubit>(() => PartnerHeaderCubit(profile))
      ..registerFactory<LoginBloc>(
        () => LoginBloc(_UnusedRequest(), _UnusedVerify()),
      );
    router = buildRouter(initialLocation: Routes.home);
  });

  Widget app({Locale locale = const Locale('en')}) => MaterialApp.router(
    theme: AppTheme.light(),
    routerConfig: router,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
  );

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('lands on Shifts with the Partner in the app bar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(location(), Routes.shifts);
    expect(find.text('No shift offers yet'), findsOneWidget);
    expect(find.text('Kavya Raman'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Open your profile')), findsOneWidget);
  });

  testWidgets('the bottom bar switches between Shifts and History', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(location(), Routes.history);
    expect(find.text('No past shifts yet'), findsOneWidget);
    // The app bar stays put across tabs.
    expect(find.text('Kavya Raman'), findsOneWidget);

    await tester.tap(find.text('Shifts'));
    await tester.pumpAndSettle();
    expect(location(), Routes.shifts);
    expect(find.text('No shift offers yet'), findsOneWidget);
  });

  testWidgets('the avatar opens the profile, and back returns to the tab', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kavya Raman'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(location(), Routes.history);
    expect(find.text('No past shifts yet'), findsOneWidget);
  });

  testWidgets('before a name is set, the header still opens the profile', (
    tester,
  ) async {
    profile.name = null;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    await tester.tap(find.text('Your profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('a network failure is quiet: fallback header, tabs still work', (
    tester,
  ) async {
    profile.fail = AuthFailure.network;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(location(), Routes.shifts);
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('a refused token sends the Partner to login', (tester) async {
    profile.fail = AuthFailure.sessionExpired;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(location(), Routes.login);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Tamil: tabs and header render without overflow', (tester) async {
    profile.name = 'கவியா';
    await tester.pumpWidget(app(locale: const Locale('ta')));
    await tester.pumpAndSettle();

    expect(find.text('வேலைகள்'), findsOneWidget);
    expect(find.text('வரலாறு'), findsOneWidget);
    expect(find.text('கவியா'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
