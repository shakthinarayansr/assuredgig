import 'package:dio/dio.dart';

/// How a call failed, in transport terms.
///
/// The `sources` layer classifies; it does not interpret. Turning one of these
/// into something a Partner reads is `data/`'s job, because only the domain
/// knows that a 400 on the OTP endpoint means "check the number".
enum ApiFailureKind {
  /// No usable connection — DNS, socket, airplane mode, captive portal.
  connection,

  /// A connection was made but the deadline passed. Common on the free-tier
  /// backend's cold start, and on 2G.
  timeout,

  /// 400 with `VALIDATION_FAILED`. The request shape was wrong.
  validation,

  /// 401 / 403.
  unauthorized,

  /// 404.
  notFound,

  /// 422. Well-formed, but refused on its merits — a wrong or expired OTP is
  /// the case that matters here. Distinct from [validation], which means the
  /// request never got as far as being considered.
  rejected,

  /// 429. [ApiException.retryAfter] carries the server's cooldown when sent.
  rateLimited,

  /// 5xx. The Partner did nothing wrong and retrying may work.
  server,

  /// The request was cancelled by us, or anything unclassified.
  unexpected,
}

/// A failed API call, stripped of anything that could carry PII.
///
/// [requestId] is the server's correlation id and is the *only* thing safe to
/// put in a log or a crash report — never the body, which holds a phone number
/// (NFR-07, and CLAUDE.md §6 "No PII in logs").
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    this.statusCode,
    this.code,
    this.requestId,
    this.retryAfter,
    this.issues = const <String>[],
  });

  final ApiFailureKind kind;
  final int? statusCode;

  /// The server's machine-readable code, e.g. `VALIDATION_FAILED`.
  final String? code;
  final String? requestId;
  final Duration? retryAfter;

  /// Validation detail. Diagnostic only — English, server-authored, and never
  /// shown to a Partner.
  final List<String> issues;

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, code: $code, '
      'requestId: $requestId)';
}

/// Recovers the [ApiException] the error interceptor attached.
///
/// `Interceptor.onError` can only reject with a [DioException], so the mapped
/// exception rides along in `error`. Providers unwrap it here so that nothing
/// above the `sources` layer ever imports Dio.
extension ApiErrorUnwrap on DioException {
  ApiException get asApiException => switch (error) {
    final ApiException api => api,
    _ => ApiException(
      kind: ApiFailureKind.unexpected,
      statusCode: response?.statusCode,
    ),
  };
}
