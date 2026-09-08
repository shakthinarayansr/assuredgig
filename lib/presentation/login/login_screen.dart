import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/login_bloc.dart';
import 'widgets/notice_banner.dart';
import 'widgets/otp_step.dart';
import 'widgets/otp_stuck_view.dart';
import 'widgets/phone_step.dart';
import 'widgets/step_header.dart';

/// S-02 and S-03 under one bloc.
///
/// Two screens in the design, one bloc and one route here, because the phone
/// number entered on the first is the input to the second — splitting them
/// would mean handing that number between two blocs and two routes, and
/// getting the back button wrong.
class LoginScreen extends StatelessWidget {
  const LoginScreen({required this.onAuthenticated, super.key});

  /// Called once the server has accepted the code. The destination the server
  /// chose is on the state; where each destination *leads* is the router's
  /// business, not this screen's.
  final void Function(AuthenticatedDestination destination) onAuthenticated;

  /// Onboarding is six steps; login is the first two. The bar spans the whole
  /// of onboarding rather than resetting per screen.
  static const int _onboardingSteps = 6;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => getIt<LoginBloc>(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == LoginStatus.authenticated,
        listener: (context, state) {
          final destination = state.destination;
          if (destination != null) onAuthenticated(destination);
        },
        builder: (context, state) {
          final bloc = context.read<LoginBloc>();
          final onPhoneStep = state.step == LoginStep.phone;

          return Scaffold(
            backgroundColor: AppTokens.ground,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  const _SlowLineNotice(),
                  StepHeader(
                    step: onPhoneStep ? 1 : 2,
                    totalSteps: _onboardingSteps,
                    // No way back out of a request in flight: the server is
                    // already deciding, and a half-abandoned verify is how a
                    // session ends up bound to the wrong device.
                    onBack: state.isBusy
                        ? null
                        : onPhoneStep
                        ? null
                        : () => bloc.add(const LoginEvent.phoneEditRequested()),
                  ),
                  Expanded(
                    child: switch (state) {
                      _ when state.needsHelp => OtpStuckView(
                        state: state,
                        bloc: bloc,
                      ),
                      _ when onPhoneStep => PhoneStep(state: state, bloc: bloc),
                      _ => OtpStep(state: state, bloc: bloc),
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The dark bar, shown once a request has been slow enough that a Partner would
/// otherwise assume the app had died.
///
/// Five seconds is chosen against a measured fact rather than a feeling: the
/// pilot backend sleeps, and its first request of the day took 52 s
/// (`ai_tools/reasoning/2026-09-08-render-cold-start-52-seconds.md`). Without
/// this, that first login looks like a hang.
class _SlowLineNotice extends StatefulWidget {
  const _SlowLineNotice();

  @override
  State<_SlowLineNotice> createState() => _SlowLineNoticeState();
}

class _SlowLineNoticeState extends State<_SlowLineNotice> {
  static const Duration _threshold = Duration(seconds: 5);

  bool _slow = false;

  /// Held so it can be cancelled. A bare `Future.delayed` cannot be, and would
  /// outlive the screen — firing into a disposed widget if the Partner leaves
  /// while a request is in flight.
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.isBusy != current.isBusy,
      listener: (context, state) {
        _timer?.cancel();
        if (state.isBusy) {
          final bloc = context.read<LoginBloc>();
          _timer = Timer(_threshold, () {
            // Still the same in-flight request, still in flight.
            if (mounted && bloc.state.isBusy) setState(() => _slow = true);
          });
        } else if (_slow) {
          setState(() => _slow = false);
        }
      },
      builder: (context, state) => _slow
          ? NoticeBanner(
              icon: Icons.signal_cellular_alt_1_bar,
              message: AppL10n.of(context).noticeSlowLine,
            )
          : const SizedBox.shrink(),
    );
  }
}
