/// Why an authentication step did not succeed.
///
/// A *code*, never a message. The presentation layer maps each value to an
/// `.arb` string — the domain layer has no locale and no `BuildContext`, and
/// CI fails the build on user-facing literals anywhere in `lib/`.
///
/// The server is the authority on every one of these (TRD §2.1): the client
/// picks a code only to choose which sentence to show.
enum AuthFailure {
  /// Unreachable, timed out, or offline. Retryable, and the only failure the
  /// UI should offer a plain "try again" for.
  network,

  /// The number is not a shape the server will accept.
  invalidPhone,

  /// Wrong code. The attempt was consumed.
  invalidOtp,

  /// The code was correct once but its window has closed. Resend, do not retry.
  otpExpired,

  /// Rate limited — too many requests or too many wrong codes. `retryAfter`
  /// on the exception carries the cooldown when the server sent one.
  tooManyAttempts,

  /// AUTH-07 / LEG-01: under 18, verified against documents. **Terminal.**
  /// No appeal affordance, no "contact support" — see CLAUDE.md §7.
  underAge,

  /// The server refused the token — 401 `UNAUTHENTICATED`. Send the Partner
  /// back to login; this is not an error to apologise for.
  ///
  /// The server returns exactly this for a missing, a malformed, *and* an
  /// expired token, so the client cannot tell "refresh me" from "you are
  /// signed out" and must assume the latter.
  sessionExpired,

  /// The account is blocked or has a deletion request in flight (AUTH-09).
  accountUnavailable,

  /// Anything unclassified. Never surface the raw cause to a Partner.
  unknown,
}

/// Thrown by the auth use cases. Carries a code and, when the server supplied
/// one, how long to wait before the action is allowed again.
class AuthException implements Exception {
  const AuthException(this.failure, {this.retryAfter});

  final AuthFailure failure;
  final Duration? retryAfter;

  @override
  String toString() => 'AuthException($failure)';
}
