part of 'login_bloc.dart';

/// Everything a Partner can do on the phone/OTP screens (S-01…S-03).
///
/// One union, both steps: the two screens are one flow, and the phone number
/// entered on the first is the input to the second. Splitting the bloc would
/// mean handing that number between two of them.
@freezed
sealed class LoginEvent with _$LoginEvent {
  /// Each keystroke in the phone field. Cheap on purpose — validation is
  /// recomputed on the state, not stored as a separate flag to fall out of sync.
  const factory LoginEvent.phoneChanged(String phone) = LoginPhoneChanged;

  /// "Send code" tapped. Ignored while a request is already in flight.
  const factory LoginEvent.otpRequested() = LoginOtpRequested;

  /// Each keystroke in the code field.
  const factory LoginEvent.codeChanged(String code) = LoginCodeChanged;

  /// "Verify" tapped, or the last digit auto-submitted.
  const factory LoginEvent.codeSubmitted() = LoginCodeSubmitted;

  /// "Resend code" tapped. Honours the cooldown the server sent; a tap before
  /// it elapses is dropped rather than rejected, so the UI stays quiet.
  const factory LoginEvent.resendRequested() = LoginResendRequested;

  /// "Wrong number?" — back to the phone step, keeping the number so it can be
  /// corrected rather than retyped. Never leave a Partner retyping.
  const factory LoginEvent.phoneEditRequested() = LoginPhoneEditRequested;

  /// The error banner was dismissed, or the field was edited after a failure.
  const factory LoginEvent.failureDismissed() = LoginFailureDismissed;
}
