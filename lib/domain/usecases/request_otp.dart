import '../entities/auth_failure.dart';

/// What the server says about the code it just sent.
///
/// Lengths and cooldowns are served, not compiled in (NFR-08, NFR-09) — the
/// client renders however many boxes the server asks for.
class OtpChallenge {
  const OtpChallenge({
    required this.codeLength,
    required this.resendAfter,
    required this.expiresIn,
  });

  final int codeLength;

  /// How long before "resend code" is offered.
  final Duration resendAfter;

  /// How long the code stays valid. The server sends this one today
  /// (`expiresInSeconds`); the other two are client defaults until it does.
  final Duration expiresIn;
}

/// Sends a one-time code to a phone number (`AuthApis.sendOtp`).
///
/// Throws [AuthException]. Implemented in `data/`; the bloc only sees this.
abstract interface class RequestOtp {
  Future<OtpChallenge> call({required String phone});
}
