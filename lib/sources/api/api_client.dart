import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../secure/token_store.dart';
import 'api_exception.dart';

/// Marks a request as needing the bearer token. Set by the providers that call
/// authenticated endpoints; read by [_AuthInterceptor].
///
/// A flag rather than path matching: a new endpoint that forgets the flag
/// fails loudly with a 401, whereas a path pattern that stops matching fails
/// silently and sends the token nowhere — or everywhere.
const String kRequiresAuth = 'requiresAuth';

/// Options that attach the Partner's access token.
Options authenticated() =>
    Options(extra: const <String, dynamic>{kRequiresAuth: true});

/// Builds the one [Dio] every API provider shares.
///
/// Registered as a singleton in `app/di.dart`, because a second Dio means a
/// second connection pool and a second set of interceptors that will drift.
Dio buildDio(TokenStore tokens) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Constants.appUrl,
      // The pilot backend is on a free tier that sleeps: a cold start measured
      // 52 s wall-clock, and a Partner on 2G is slow again on top of that.
      // Warm calls return in well under a second, so a generous ceiling costs
      // nothing in the normal case and prevents a spurious "no connection" in
      // the worst one.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      // 4xx must reach our own mapping as a DioException rather than being
      // treated as a body to parse.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  dio.interceptors.add(_AuthInterceptor(tokens));
  dio.interceptors.add(const _ErrorMappingInterceptor());
  return dio;
}

/// Attaches `Authorization: Bearer …` to requests that asked for it.
///
/// It does not pre-empt an expired token, even though [StoredSession] knows the
/// expiry: the server decides whether a token is good, and a client that
/// decides is a client that can be made to lie (TRD §2.1). The cost of being
/// wrong is one 401.
///
/// **No silent refresh yet.** TRD §8 requires single-flight refresh on a 401,
/// and there is no refresh endpoint on the backend to call — `AuthApis` knows
/// three paths and none of them mints a token from a refresh token. Until one
/// exists, a 401 surfaces as a session-expired failure and the Partner logs
/// in again. This interceptor is where that retry belongs when it does.
class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._tokens);

  final TokenStore _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kRequiresAuth] != true) {
      handler.next(options);
      return;
    }

    final session = await _tokens.read();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    // A missing token still goes out: the 401 that comes back is the same
    // answer, through one code path instead of two.
    handler.next(options);
  }
}

/// Turns a [DioException] into an [ApiException] once, centrally, so no
/// provider has to know what a `DioExceptionType` is.
class _ErrorMappingInterceptor extends Interceptor {
  const _ErrorMappingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: _toApiException(err),
      ),
    );
  }

  ApiException _toApiException(DioException err) {
    final response = err.response;
    final body = response?.data;
    final envelope = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};

    final code = envelope['code'] as String?;
    final requestId = envelope['requestId'] as String?;
    final issues = switch (envelope['details']) {
      {'issues': final List<dynamic> list} => list.whereType<String>().toList(),
      _ => const <String>[],
    };

    final status = response?.statusCode;
    final kind = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => ApiFailureKind.timeout,
      DioExceptionType.connectionError => ApiFailureKind.connection,
      DioExceptionType.badCertificate => ApiFailureKind.connection,
      DioExceptionType.cancel => ApiFailureKind.unexpected,
      DioExceptionType.badResponse ||
      DioExceptionType.unknown => switch (status) {
        400 => ApiFailureKind.validation,
        401 || 403 => ApiFailureKind.unauthorized,
        404 => ApiFailureKind.notFound,
        422 => ApiFailureKind.rejected,
        429 => ApiFailureKind.rateLimited,
        final int s when s >= 500 => ApiFailureKind.server,
        _ => ApiFailureKind.unexpected,
      },
    };

    return ApiException(
      kind: kind,
      statusCode: status,
      code: code,
      requestId: requestId,
      retryAfter: _retryAfter(response),
      issues: issues,
    );
  }

  /// `Retry-After` is seconds or an HTTP date; only the seconds form is worth
  /// honouring here — a date form falls back to the client's own cooldown.
  Duration? _retryAfter(Response<dynamic>? response) {
    final header = response?.headers.value('retry-after');
    final seconds = header == null ? null : int.tryParse(header);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
