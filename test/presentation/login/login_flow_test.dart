import 'package:assuredgig/core/theme/app_tokens.dart';
import 'package:assuredgig/domain/entities/auth_failure.dart';
import 'package:assuredgig/domain/usecases/request_otp.dart';
import 'package:assuredgig/domain/usecases/verify_otp.dart';
import 'package:assuredgig/l10n/app_localizations.dart';
import 'package:assuredgig/presentation/login/bloc/login_bloc.dart';
import 'package:assuredgig/presentation/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _FakeRequest implements RequestOtp {
  int calls = 0;
  @override
  Future<OtpChallenge> call({required String phone}) async {
    calls++;
    return const OtpChallenge(
      codeLength: 6,
      resendAfter: Duration(seconds: 24),
      expiresIn: Duration(minutes: 5),
    );
  }
}

class _FakeVerify implements VerifyOtp {
  AuthFailure? fail;
  @override
  Future<AuthenticatedDestination> call({
    required String phone,
    required String code,
  }) async {
    if (fail != null) throw AuthException(fail!);
    return AuthenticatedDestination.onboarding;
  }
}

Widget _app(Locale locale, {void Function(AuthenticatedDestination)? onAuth}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: LoginScreen(onAuthenticated: onAuth ?? (_) {}),
    );

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.widgetWithText(InkWell, d).first);
    await tester.pump();
  }
}

void main() {
  late _FakeRequest request;
  late _FakeVerify verify;

  setUp(() async {
    request = _FakeRequest();
    verify = _FakeVerify();
    await GetIt.I.reset();
    GetIt.I.registerFactory<LoginBloc>(() => LoginBloc(request, verify));
  });

  testWidgets('phone -> otp -> authenticated, driven by the pad', (
    tester,
  ) async {
    AuthenticatedDestination? landed;
    await tester.pumpWidget(
      _app(const Locale('en'), onAuth: (d) => landed = d),
    );

    expect(find.text('Your phone number'), findsOneWidget);
    expect(find.text('Type your number'), findsOneWidget);
    // Server-driven digit count, not the canvas's 4.
    expect(find.text('We send a 6-digit code by SMS.'), findsOneWidget);

    await _tapDigits(tester, '90035');
    expect(find.text('5 of 10 digits'), findsWidgets);

    await _tapDigits(tester, '60015');
    expect(find.text('Send me the code'), findsOneWidget);

    await tester.tap(find.text('Send me the code'));
    await tester.pump();
    await tester.pump();
    expect(request.calls, 1);
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('Sent to +91 90035 60015'), findsOneWidget);
    expect(find.text('Type 6 digits'), findsOneWidget);

    await _tapDigits(tester, '123456');
    expect(find.text('Check the code'), findsOneWidget);
    await tester.tap(find.text('Check the code'));
    await tester.pump();
    await tester.pump();
    expect(landed, AuthenticatedDestination.onboarding);
    await tester.pumpAndSettle();
  });

  testWidgets('three wrong codes reach the help screen', (tester) async {
    verify.fail = AuthFailure.invalidOtp;
    await tester.pumpWidget(_app(const Locale('en')));

    await _tapDigits(tester, '9003560015');
    await tester.tap(find.text('Send me the code'));
    await tester.pump();
    await tester.pump();

    for (var attempt = 0; attempt < 3; attempt++) {
      await _tapDigits(tester, '000000');
      await tester.tap(find.text('Check the code'));
      await tester.pump();
      await tester.pump();
      if (attempt < 2) {
        expect(
          find.text("Doesn't match. Check the SMS and fix the wrong digits."),
          findsOneWidget,
        );
      }
    }

    expect(
      find.text("The code isn't working. We'll do it by phone."),
      findsOneWidget,
    );
    expect(find.text('Change my number'), findsOneWidget);
    // The canvas's call button is absent — no ops number exists to dial.
    expect(find.text('Call our team'), findsNothing);

    await tester.tap(find.text('Change my number'));
    await tester.pump();
    expect(find.text('Your phone number'), findsOneWidget);
    // The number is kept for correction, not retyped.
    expect(find.text('90035 60015'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders in Tamil without overflow', (tester) async {
    await tester.pumpWidget(_app(const Locale('ta')));
    expect(find.text('உங்கள் தொலைபேசி எண்'), findsOneWidget);
    await _tapDigits(tester, '9003560015');
    await tester.tap(find.text('எனக்கு குறியீட்டை அனுப்புங்கள்'));
    await tester.pump();
    await tester.pump();
    expect(find.text('குறியீட்டை உள்ளிடுங்கள்'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('tap targets clear the 48 dp floor', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    for (final d in <String>['1', '5', '0']) {
      final size = tester.getSize(find.widgetWithText(InkWell, d).first);
      expect(size.height, greaterThanOrEqualTo(AppTokens.targetKey));
    }
    await _tapDigits(tester, '9003560015');
    expect(
      tester.getSize(find.widgetWithText(InkWell, 'Send me the code')).height,
      greaterThanOrEqualTo(AppTokens.targetCta),
    );
  });
}
