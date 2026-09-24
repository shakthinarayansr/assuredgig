part of 'login_bloc.dart';

/// Which of the two steps the flow is on.
enum LoginStep { phone, code }

/// What the bloc is doing right now, orthogonal to which step it is on.
enum LoginStatus {
  /// Waiting for input. The only state in which a submit is accepted.
  editing,

  /// A request is in flight. Every action is disabled and the button shows a
  /// spinner — a double-tap must not send two codes.
  submitting,

  /// Verified. The screen listens for this and routes to [destination].
  authenticated,
}

/// One flat state for the whole flow rather than a union per step.
///
/// The step is a field because the phone number survives across it, and because
/// a union would make "submitting on the code step, with a stale failure still
/// on screen" a state you have to construct by hand every time.
@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    required LoginStep step,
    required LoginStatus status,

    /// Digits only, as typed. Formatting for display belongs to the screen.
    required String phone,
    required String code,

    /// Null unless the last action failed. A *code* — the screen maps it to an
    /// `.arb` string, and the message names the next action, not the fault.
    AuthFailure? failure,

    /// How many digits the server asked for. Served, not compiled in
    /// (NFR-08) — the default is only what to render before the first reply.
    @Default(6) int codeLength,

    /// Digits the server accepts in a phone number. Same story: this is the
    /// India pilot's shape, and it moves to server config when config lands.
    @Default(10) int phoneLength,

    /// When resending becomes allowed. The screen counts down against the
    /// clock; keeping a `Timer` out of the bloc keeps it trivially testable.
    DateTime? resendAvailableAt,

    /// Set exactly when [status] is [LoginStatus.authenticated].
    AuthenticatedDestination? destination,

    /// Wrong codes entered in a row. Drives the "we'll do it by phone" screen
    /// after [maxCodeAttempts] — a **wording** decision, not an eligibility
    /// one: the server still decides whether any given code is valid, and it
    /// keeps its own rate limit regardless of this counter (TRD §2.1).
    @Default(0) int wrongCodeAttempts,
  }) = _LoginState;

  const LoginState._();

  factory LoginState.initial() => const LoginState(
    step: LoginStep.phone,
    status: LoginStatus.editing,
    phone: '',
    code: '',
  );

  bool get isBusy => status == LoginStatus.submitting;

  /// Shape only, and only to decide whether the button looks enabled. The
  /// server re-validates: a client that decides is a client that can be made
  /// to lie (TRD §2.1).
  bool get isPhoneValid => phone.length == phoneLength;

  bool get isCodeComplete => code.length == codeLength;

  bool get canRequestOtp => isPhoneValid && !isBusy;

  bool get canSubmitCode => isCodeComplete && !isBusy;

  /// Resend is allowed once the server's cooldown has elapsed. [now] is passed
  /// in rather than read from the clock so a widget test can drive it.
  bool canResendAt(DateTime now) =>
      !isBusy &&
      (resendAvailableAt == null || !now.isBefore(resendAvailableAt!));

  /// AUTH-07: rejection is terminal. The screen shows no retry, no appeal and
  /// no "contact support" affordance for this one.
  bool get isTerminal => failure == AuthFailure.underAge;

  /// After this many wrong codes, stop asking the Partner to try harder.
  static const int maxCodeAttempts = 3;

  /// Time to offer a way out rather than another empty field.
  ///
  /// Either the Partner has missed three times, or the server has started
  /// refusing — both mean the code path is not working for this person right
  /// now, and a fourth identical screen is not help.
  bool get needsHelp =>
      step == LoginStep.code &&
      (wrongCodeAttempts >= maxCodeAttempts ||
          failure == AuthFailure.tooManyAttempts);
}
