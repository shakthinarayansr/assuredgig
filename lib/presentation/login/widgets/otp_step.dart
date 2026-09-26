import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/login_bloc.dart';
import '../failure_copy.dart';
import 'number_pad.dart';
import 'pill_button.dart';

/// S-03 — code entry.
///
/// The number of boxes is [LoginState.codeLength], which the **server** sets
/// via `OtpChallenge`. The canvas draws four; the live API rejects any code
/// shorter than six. Rendering the served length means the screen is right
/// whichever the backend settles on, and the copy reads the same number.
class OtpStep extends StatefulWidget {
  const OtpStep({required this.state, required this.bloc, super.key});

  final LoginState state;
  final LoginBloc bloc;

  @override
  State<OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<OtpStep> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The cooldown lives in the bloc as an absolute instant, so this only
    // repaints — no countdown state to drift, and closing the screen mid-count
    // loses nothing.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final p = AppPalette.of(context);
    final state = widget.state;
    final bloc = widget.bloc;
    final busy = state.isBusy;
    final failure = state.failure;

    final now = DateTime.now();
    final resendAt = state.resendAvailableAt;
    final secondsLeft = resendAt == null
        ? 0
        : resendAt.difference(now).inSeconds.clamp(0, 3599);
    final canResend = state.canResendAt(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.otpTitle,
                  style: AppTokens.question.copyWith(
                    // Recedes while the server is deciding, so the spinner is
                    // the live thing on the screen.
                    color: busy ? p.textDisabled : p.text,
                  ),
                ),
                if (!busy) ...<Widget>[
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: l10n.otpSentTo(_pretty(state.phone)),
                          style: AppTokens.body.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _OtpBoxes(state: state, hasError: failure != null),
                if (busy) ...<Widget>[
                  const SizedBox(height: 26),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.primary,
                          backgroundColor: p.divider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          l10n.otpChecking,
                          style: AppTokens.rowLabel.copyWith(color: p.text),
                        ),
                      ),
                    ],
                  ),
                ] else if (failure != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 16, color: p.danger),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          failure.message(l10n),
                          style: AppTokens.hint.copyWith(
                            color: p.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.timer_outlined, size: 16, color: p.textMuted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          canResend
                              ? l10n.otpResendNow
                              : l10n.otpResendIn(secondsLeft),
                          style: AppTokens.hint.copyWith(color: p.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!busy && canResend) ...<Widget>[
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () =>
                          bloc.add(const LoginEvent.resendRequested()),
                      style: TextButton.styleFrom(
                        foregroundColor: p.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, AppTokens.targetMin),
                      ),
                      child: Text(
                        l10n.otpResendAction,
                        style: AppTokens.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: PillButton(
            label: busy
                ? l10n.otpCtaWaiting
                : state.isCodeComplete
                ? l10n.otpCtaReady
                : l10n.otpCtaIncomplete(state.codeLength),
            onPressed: state.canSubmitCode
                ? () => bloc.add(const LoginEvent.codeSubmitted())
                : null,
          ),
        ),
        NumberPad(
          onDigit: (digit) =>
              bloc.add(LoginEvent.codeChanged('${state.code}$digit')),
          onBackspace: () => bloc.add(
            LoginEvent.codeChanged(
              state.code.isEmpty
                  ? ''
                  : state.code.substring(0, state.code.length - 1),
            ),
          ),
        ),
      ],
    );
  }

  /// `9003560015` → `+91 90035 60015`. Grouped the way it is read aloud, so a
  /// Partner checking the number against their SIM can scan it.
  static String _pretty(String digits) {
    final grouped = digits.length > 5
        ? '${digits.substring(0, 5)} ${digits.substring(5)}'
        : digits;
    return '+91 $grouped';
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({required this.state, required this.hasError});

  final LoginState state;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final busy = state.isBusy;
    final p = AppPalette.of(context);

    return Opacity(
      opacity: busy ? 0.5 : 1,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < state.codeLength; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: AppTokens.targetOtpBox,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: busy
                      ? p.sky
                      : (i < state.code.length ? p.surface : p.surfaceAlt),
                  borderRadius: BorderRadius.circular(AppTokens.radiusField),
                  border: Border.all(
                    color: switch ((hasError, busy)) {
                      (true, _) => p.danger,
                      (_, true) => p.divider,
                      // The next box to be filled carries the accent — the
                      // caret, without a caret.
                      _ when i == state.code.length => p.primary,
                      _ => p.divider,
                    },
                  ),
                ),
                child: Text(
                  i < state.code.length ? state.code[i] : '',
                  style: AppTokens.otpDigit.copyWith(color: p.text),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
