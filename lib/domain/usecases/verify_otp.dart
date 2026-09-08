import '../entities/auth_failure.dart';

/// Where a Partner lands once the code is accepted.
///
/// The server decides this, not the client — a half-onboarded Partner must not
/// be able to reach the shifts list by guessing a route.
enum AuthenticatedDestination {
  /// Profile is complete and verified. Straight to the app shell.
  ready,

  /// Signed in, but onboarding is unfinished (PROF-01…08).
  onboarding,

  /// Profile is submitted and waiting on ops to vet it — the server's
  /// `PENDING_VETTING`. No offers arrive yet, so the shifts list would be an
  /// empty screen with no explanation. Show the waiting state instead.
  ///
  /// Also the fallback for a status this build does not recognise: witnessing
  /// an unknown state as "not yet cleared" is the safe direction to be wrong
  /// in (TRD §2.1).
  pendingVetting,
}

/// Exchanges a code for a session (`AuthApis.verifyOtp`).
///
/// The implementation writes tokens to secure storage and returns only where to
/// go next — tokens never reach a bloc or a state object (TRD §8, NFR-05).
///
/// Throws [AuthException].
abstract interface class VerifyOtp {
  Future<AuthenticatedDestination> call({
    required String phone,
    required String code,
  });
}
