import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/worker_status.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../sources/api/api_exception.dart';
import '../../sources/api/auth_api_provider.dart';
import '../../sources/device/device_id_provider.dart';
import '../../sources/secure/token_store.dart';
import '../mappers/worker_mappers.dart';

/// Binds [VerifyOtp] to the live backend.
///
/// This is where the tokens stop. They go from the response straight into
/// [TokenStore] and the caller gets back a destination — so no token is ever
/// reachable from a bloc, a state object, or a crash report (NFR-05, NFR-07).
@Injectable(as: VerifyOtp)
class VerifyOtpFromApi implements VerifyOtp {
  const VerifyOtpFromApi(this._api, this._deviceId, this._tokens);

  final AuthApiProvider _api;
  final DeviceIdProvider _deviceId;
  final TokenStore _tokens;

  /// Single-country pilot; moves to served config alongside the one in
  /// `otp_repository.dart` the moment a second dial code exists (NFR-08).
  static const String _dialCode = '+91';

  @override
  Future<AuthenticatedDestination> call({
    required String phone,
    required String code,
  }) async {
    try {
      final session = await _api.verifyOtp(
        phone: _toE164(phone),
        code: code,
        deviceId: await _deviceId.get(),
      );

      // Persisted before the destination is returned: the caller navigating on
      // this result must not be able to land on an authenticated screen a
      // moment before the token it needs exists on disk.
      await _tokens.save(
        StoredSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          // The server sends a lifetime, not an instant. Anchoring it to the
          // device clock is what the TRD's silent refresh reads later; the
          // server re-checks regardless, so a skewed clock costs a round trip,
          // not a wrong decision.
          accessTokenExpiresAt: DateTime.now().add(session.expiresIn),
          sessionId: session.sessionId,
          workerId: session.workerId,
        ),
      );

      return _destinationFor(session);
    } on ApiException catch (error) {
      throw AuthException(_failureFor(error), retryAfter: error.retryAfter);
    }
  }

  /// Where the server says this Partner belongs. The client reads the verdict;
  /// it does not compute one (TRD §2.1).
  AuthenticatedDestination _destinationFor(VerifyOtpResponse session) {
    if (!session.profileComplete) return AuthenticatedDestination.onboarding;
    // Shares the profile endpoint's status vocabulary — the two must not be
    // allowed to disagree about what `PENDING_VETTING` means.
    return switch (WorkerStatusWire.fromWire(session.status)) {
      WorkerStatus.active => AuthenticatedDestination.ready,
      WorkerStatus.pendingVetting ||
      WorkerStatus.inactive ||
      WorkerStatus.unknown => AuthenticatedDestination.pendingVetting,
    };
  }

  String _toE164(String phone) {
    final trimmed = phone.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return '$_dialCode${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  AuthFailure _failureFor(ApiException error) => switch (error.kind) {
    ApiFailureKind.connection || ApiFailureKind.timeout => AuthFailure.network,

    // 422 INVALID_CODE. The server returns the same code for a wrong entry and
    // an expired one — its own message says "expired" either way — so the
    // client cannot honestly distinguish them. `invalidOtp` is the safer of
    // the two to show: it tells the Partner to check the code, and the resend
    // affordance is on screen regardless.
    ApiFailureKind.rejected => AuthFailure.invalidOtp,

    // 400. The phone was already accepted at the request step and the device
    // id is ours, so in practice this is the code failing its length rule.
    ApiFailureKind.validation => AuthFailure.invalidOtp,

    ApiFailureKind.rateLimited => AuthFailure.tooManyAttempts,
    ApiFailureKind.unauthorized => switch (error.code) {
      'AGE_INELIGIBLE' => AuthFailure.underAge,
      'ACCOUNT_BLOCKED' || 'ACCOUNT_DELETED' => AuthFailure.accountUnavailable,
      _ => AuthFailure.unknown,
    },
    ApiFailureKind.server ||
    ApiFailureKind.notFound ||
    ApiFailureKind.unexpected => AuthFailure.unknown,
  };
}
