import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/api_endpoints.dart';
import 'api_exception.dart';

/// The server's reply to `POST /v1/auth/otp/request`.
///
/// Verbatim `{"expiresInSeconds": 300}` — no more is invented than the server
/// actually sends. A cooldown and a code length would both belong here; until
/// the server sends them, `data/` supplies the defaults and says so.
class OtpRequestResponse {
  const OtpRequestResponse({required this.expiresIn});

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    final seconds = json['expiresInSeconds'];
    return OtpRequestResponse(
      expiresIn: Duration(seconds: seconds is num ? seconds.toInt() : 300),
    );
  }

  /// How long the emitted code stays valid.
  final Duration expiresIn;
}

/// The server's reply to `POST /v1/auth/otp/verify`.
///
/// Mirrors the payload exactly, including the fields nothing consumes yet
/// (`issuedId`, `isNewWorker`): dropping them here would mean re-reading the
/// endpoint later to find out they existed.
class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.sessionId,
    required this.workerId,
    required this.status,
    required this.isNewWorker,
    required this.profileComplete,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expiresIn'];
    return VerifyOtpResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: Duration(seconds: expiresIn is num ? expiresIn.toInt() : 0),
      // `issuedId` server-side; `sessionId` here, because that is what it is —
      // the handle for the device-bound session that a later login supersedes.
      sessionId: json['issuedId'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isNewWorker: json['isNewWorker'] as bool? ?? false,
      profileComplete: json['profileComplete'] as bool? ?? false,
    );
  }

  final String accessToken;
  final String refreshToken;

  /// Lifetime of [accessToken] — 900 s today. Short by design; the refresh
  /// token is what survives, and silent refresh is single-flight (TRD §8).
  final Duration expiresIn;

  final String sessionId;
  final String workerId;

  /// Vetting state, e.g. `PENDING_VETTING`. Interpreted in `data/` — the
  /// provider does not know what the values mean.
  final String status;

  final bool isNewWorker;
  final bool profileComplete;
}

/// Talks to the auth endpoints. One method per call, no logic.
///
/// **This is hand-written, which the TRD forbids** — §3 requires a generated
/// OpenAPI client, and CLAUDE.md §5 records that no networked feature is
/// finished until the spec exists. There is no spec in this repo yet, so this
/// stands in for the generated `AuthApi` and is deliberately shaped like one:
/// DTO in, DTO out, no mapping, no domain types. When the spec lands, this file
/// is deleted and `data/` binds to the generated client instead — which is the
/// whole reason the repository below, not a bloc, is what depends on it.
@lazySingleton
class AuthApiProvider {
  const AuthApiProvider(this._dio);

  final Dio _dio;

  /// Asks the server to send a one-time code.
  ///
  /// [phone] must already be E.164 (`+919003560015`) — the server rejects
  /// anything else with `VALIDATION_FAILED`. Normalising is `data/`'s job,
  /// because the dial code is a policy decision, not a transport one.
  ///
  /// Throws [ApiException] (mapped by the interceptor in `api_client.dart`).
  Future<OtpRequestResponse> requestOtp({required String phone}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthApis.sendOtp,
        data: <String, String>{'phone': phone},
      );
      return OtpRequestResponse.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw error.asApiException;
    }
  }

  /// Exchanges a code for a session.
  ///
  /// [phone] is E.164 and [deviceId] is at least 8 characters — the server
  /// rejects both otherwise with `VALIDATION_FAILED`. The device id is what
  /// binds the session to this handset: sending a different one supersedes the
  /// previous session rather than opening a second (TRD §8).
  ///
  /// The returned tokens are secrets. They go straight to secure storage in
  /// `data/` and must never be logged, put in a crash breadcrumb, or held in a
  /// bloc's state (NFR-05, NFR-07).
  ///
  /// Throws [ApiException] — notably `kind: rejected` (HTTP 422,
  /// `INVALID_CODE`) for a wrong *or* expired code; the server does not
  /// distinguish the two.
  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String code,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthApis.verifyOtp,
        data: <String, String>{
          'phone': phone,
          'code': code,
          'deviceId': deviceId,
        },
      );
      return VerifyOtpResponse.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw error.asApiException;
    }
  }
}
