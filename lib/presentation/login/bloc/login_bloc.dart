import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/auth_failure.dart';
import '../../../domain/usecases/request_otp.dart';
import '../../../domain/usecases/verify_otp.dart';

part 'login_bloc.freezed.dart';
part 'login_event.dart';
part 'login_state.dart';

/// Phone + OTP sign-in (AUTH-01…AUTH-07, S-01…S-03).
///
/// Auth is the one place a bloc awaits the network directly: there is no
/// session yet, so there is nothing for the outbox to authenticate as, and a
/// queued login is not a login. Every *other* write in this app is an outbox
/// row (CLAUDE.md §2).
///
/// The bloc holds no token. [VerifyOtp] writes them to secure storage and hands
/// back only where to go next, so nothing sensitive lands in a state object
/// that a crash reporter or a devtools inspector could read (NFR-05, NFR-07).
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._requestOtp, this._verifyOtp) : super(LoginState.initial()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginOtpRequested>(_onOtpRequested);
    on<LoginCodeChanged>(_onCodeChanged);
    on<LoginCodeSubmitted>(_onCodeSubmitted);
    on<LoginResendRequested>(_onResendRequested);
    on<LoginPhoneEditRequested>(_onPhoneEditRequested);
    on<LoginFailureDismissed>(_onFailureDismissed);
  }

  final RequestOtp _requestOtp;
  final VerifyOtp _verifyOtp;

  /// Non-digits are dropped rather than rejected, so a number pasted with
  /// spaces or dashes does the obvious thing instead of being refused.
  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    if (state.isBusy) return;

    final raw = event.phone.trim();
    final digits = raw.replaceAll(_nonDigits, '');

    // A pasted international number carries a dial code in front, so an
    // overlong value has to be trimmed from the left, not the right. The `+`
    // is the only signal used — no dial code is compiled in (NFR-08), and a
    // number that is merely mistyped keeps its leading digits.
    final national = raw.startsWith('+') && digits.length > state.phoneLength
        ? digits.substring(digits.length - state.phoneLength)
        : digits.substring(0, math.min(digits.length, state.phoneLength));

    emit(state.copyWith(phone: national, failure: null));
  }

  Future<void> _onOtpRequested(
    LoginOtpRequested event,
    Emitter<LoginState> emit,
  ) => _sendCode(emit);

  void _onCodeChanged(LoginCodeChanged event, Emitter<LoginState> emit) {
    if (state.isBusy) return;
    final digits = event.code.replaceAll(_nonDigits, '');
    emit(
      state.copyWith(
        code: digits.substring(0, math.min(digits.length, state.codeLength)),
        failure: null,
      ),
    );
  }

  Future<void> _onCodeSubmitted(
    LoginCodeSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.canSubmitCode) return;
    emit(state.copyWith(status: LoginStatus.submitting, failure: null));

    try {
      final destination = await _verifyOtp(
        phone: state.phone,
        code: state.code,
      );
      emit(
        state.copyWith(
          status: LoginStatus.authenticated,
          destination: destination,
        ),
      );
    } on AuthException catch (error) {
      // The code is cleared on a wrong or expired one so the boxes are ready
      // for the next attempt; kept otherwise, because a rate limit is not the
      // Partner mistyping.
      final wasCodeRejected =
          error.failure == AuthFailure.invalidOtp ||
          error.failure == AuthFailure.otpExpired;
      emit(
        state.copyWith(
          status: LoginStatus.editing,
          failure: error.failure,
          code: wasCodeRejected ? '' : state.code,
          resendAvailableAt: _cooldownFrom(error) ?? state.resendAvailableAt,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoginStatus.editing,
          failure: AuthFailure.unknown,
        ),
      );
    }
  }

  Future<void> _onResendRequested(
    LoginResendRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.canResendAt(DateTime.now())) return;
    await _sendCode(emit);
  }

  void _onPhoneEditRequested(
    LoginPhoneEditRequested event,
    Emitter<LoginState> emit,
  ) {
    if (state.isBusy) return;
    // The number is deliberately kept: it is corrected, not retyped.
    emit(
      state.copyWith(
        step: LoginStep.phone,
        status: LoginStatus.editing,
        code: '',
        failure: null,
        resendAvailableAt: null,
      ),
    );
  }

  void _onFailureDismissed(
    LoginFailureDismissed event,
    Emitter<LoginState> emit,
  ) {
    // A terminal rejection stays on screen. There is nothing to dismiss it to.
    if (state.isTerminal) return;
    emit(state.copyWith(failure: null));
  }

  /// Shared by the first send and every resend — one code path, so the cooldown
  /// and the step transition cannot diverge between them.
  Future<void> _sendCode(Emitter<LoginState> emit) async {
    if (!state.canRequestOtp) return;
    emit(state.copyWith(status: LoginStatus.submitting, failure: null));

    try {
      final challenge = await _requestOtp(phone: state.phone);
      emit(
        state.copyWith(
          step: LoginStep.code,
          status: LoginStatus.editing,
          code: '',
          codeLength: challenge.codeLength,
          resendAvailableAt: DateTime.now().add(challenge.resendAfter),
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.editing,
          failure: error.failure,
          resendAvailableAt: _cooldownFrom(error) ?? state.resendAvailableAt,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoginStatus.editing,
          failure: AuthFailure.unknown,
        ),
      );
    }
  }

  DateTime? _cooldownFrom(AuthException error) {
    final retryAfter = error.retryAfter;
    return retryAfter == null ? null : DateTime.now().add(retryAfter);
  }
}
