import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/auth_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/login_bloc.dart';
import '../failure_copy.dart';
import 'number_pad.dart';
import 'pill_button.dart';

/// S-02 — the number entry step.
///
/// There is no `TextField`: the digits are state, the pad writes to it, and the
/// row below the label is a rendering of that state with a caret drawn in. That
/// removes the system IME, autocorrect, and every paste-shaped surprise from
/// the one field this flow cannot get wrong.
class PhoneStep extends StatelessWidget {
  const PhoneStep({required this.state, required this.bloc, super.key});

  final LoginState state;
  final LoginBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final failure = state.failure;

    // The hint carries one of three things, in priority order: the server's
    // objection, the shape expected, or how far along the Partner is.
    final (String hintText, IconData hintIcon, Color hintColour) = switch ((
      failure,
      state.phone.length,
    )) {
      // A non-nullable pattern already excludes the no-failure case.
      (final AuthFailure f, _) => (
        f.message(l10n),
        Icons.error_outline,
        AppTokens.errorInk,
      ),
      (_, 0) => (
        l10n.phoneHintEmpty(state.phoneLength),
        Icons.info_outline,
        AppTokens.inkFaint,
      ),
      (_, final int typed) => (
        l10n.phoneHintProgress(typed, state.phoneLength),
        state.isPhoneValid ? Icons.check_circle_outline : Icons.info_outline,
        AppTokens.inkFaint,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.phoneTitle, style: AppTokens.question),
                const SizedBox(height: 8),
                // The digit count is the server's, not ours. The canvas says
                // "4-digit"; the live API rejects anything under 6.
                Text(
                  l10n.phoneSubtitle(state.codeLength),
                  style: AppTokens.body,
                ),
                const SizedBox(height: 26),
                _PhoneField(state: state, hasError: failure != null),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(hintIcon, size: 16, color: hintColour),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        hintText,
                        style: AppTokens.hint.copyWith(
                          color: hintColour,
                          fontWeight: failure == null
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: PillButton(
            label: switch (state.phone.length) {
              0 => l10n.phoneCtaEmpty,
              _ when state.isPhoneValid => l10n.phoneCtaReady,
              final int typed => l10n.phoneHintProgress(
                typed,
                state.phoneLength,
              ),
            },
            onPressed: state.canRequestOtp
                ? () => bloc.add(const LoginEvent.otpRequested())
                : null,
          ),
        ),
        NumberPad(
          onDigit: (digit) =>
              bloc.add(LoginEvent.phoneChanged('${state.phone}$digit')),
          onBackspace: () => bloc.add(
            LoginEvent.phoneChanged(
              state.phone.isEmpty
                  ? ''
                  : state.phone.substring(0, state.phone.length - 1),
            ),
          ),
        ),
      ],
    );
  }
}

/// `+91`, the digits, and a caret — underlined by a 2 dp accent rule that turns
/// red on a rejection.
class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.state, required this.hasError});

  final LoginState state;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final digits = state.phone;
    // Grouped 5 + 5, the way the number is read aloud.
    final display = digits.length > 5
        ? '${digits.substring(0, 5)} ${digits.substring(5)}'
        : digits;

    return Container(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: hasError ? AppTokens.error : AppTokens.accent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // The dial code is fixed for the pilot and shown rather than typed,
          // so it cannot be half-entered. It is added again in `data/` on the
          // way out, where E.164 belongs.
          Text(
            '+91', // i18n-ignore: a dial code is not translated text.
            style: AppTokens.digits.copyWith(color: AppTokens.inkFaint),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(display, style: AppTokens.digits)),
          if (!state.isPhoneValid) ...<Widget>[
            const SizedBox(width: 2),
            Container(width: 2, height: 30, color: AppTokens.accent),
          ],
        ],
      ),
    );
  }
}
