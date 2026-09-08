import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/login_bloc.dart';
import 'pill_button.dart';

/// Shown after three wrong codes, or when the server starts refusing.
///
/// The point is to stop asking. A fourth identical screen is not help, and the
/// Partner most likely to be stuck here — bad SMS reception, a borrowed handset,
/// a number typed from memory — is the one least able to solve it alone.
///
/// ⚠ **The canvas's "Call our team" button is missing**, and deliberately so:
/// no ops phone number exists in the BRD, the PRD, the TRD, or any config
/// endpoint, and inventing one would print a number that does not answer. The
/// two remaining actions both work, so the screen still leaves a next step —
/// but it is a weaker screen than the one designed. See
/// `ai_tools/proposals/2026-09-09-ops-support-number.md`.
class OtpStuckView extends StatelessWidget {
  const OtpStuckView({required this.state, required this.bloc, super.key});

  final LoginState state;
  final LoginBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final canResend = state.canResendAt(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.darkGround,
              borderRadius: BorderRadius.circular(AppTokens.radiusField),
            ),
            child: const Icon(
              Icons.support_agent,
              size: 24,
              color: AppTokens.notice,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.otpStuckTitle,
            style: AppTokens.question.copyWith(fontSize: 26, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(l10n.otpStuckBody, style: AppTokens.body.copyWith(height: 1.55)),
          const SizedBox(height: 22),
          PillButton(
            label: l10n.otpResendAction,
            variant: PillVariant.secondary,
            onPressed: canResend
                ? () => bloc.add(const LoginEvent.resendRequested())
                : null,
          ),
          const SizedBox(height: 10),
          PillButton(
            label: l10n.otpChangeNumber,
            variant: PillVariant.ghost,
            onPressed: () => bloc.add(const LoginEvent.phoneEditRequested()),
          ),
          const SizedBox(height: 26),
          Text(
            l10n.otpStuckFooter,
            style: AppTokens.hint.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
