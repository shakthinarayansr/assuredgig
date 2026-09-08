import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/usecases/request_otp.dart';
import '../../sources/api/api_exception.dart';
import '../../sources/api/auth_api_provider.dart';

/// Binds [RequestOtp] to the live backend.
///
/// This is the seam the whole layering exists for: `LoginBloc` depends on the
/// abstract use case, so swapping the hand-written provider for the generated
/// OpenAPI client — or a fake, in a test — touches this file and nothing else.
@Injectable(as: RequestOtp)
class RequestOtpFromApi implements RequestOtp {
  const RequestOtpFromApi(this._api);

  final AuthApiProvider _api;

  /// The pilot is single-country, and the server insists on E.164. It is here
  /// rather than in the bloc because it is a policy decision, and it moves to
  /// the served config the moment a second dial code exists (NFR-08).
  static const String _dialCode = '+91';

  /// Client defaults, used only because the server does not send them yet.
  /// The instant `POST /v1/auth/otp/request` returns a code length or a resend
  /// cooldown, read them off the response and delete these.
  static const int _defaultCodeLength = 6;
  static const Duration _defaultResendAfter = Duration(seconds: 30);

  @override
  Future<OtpChallenge> call({required String phone}) async {
    try {
      final response = await _api.requestOtp(phone: _toE164(phone));
      return OtpChallenge(
        codeLength: _defaultCodeLength,
        resendAfter: _defaultResendAfter,
        expiresIn: response.expiresIn,
      );
    } on ApiException catch (error) {
      throw AuthException(_failureFor(error), retryAfter: error.retryAfter);
    }
  }

  /// The bloc holds a national number, digits only. The server wants
  /// `+919003560015` and rejects everything else with `VALIDATION_FAILED`.
  String _toE164(String phone) {
    final trimmed = phone.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return '$_dialCode${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  /// Transport failure to something the screen can put a sentence to.
  ///
  /// The string codes are provisional: only `VALIDATION_FAILED` is confirmed
  /// against the running backend. Anything unrecognised deliberately falls
  /// through to [AuthFailure.unknown] rather than guessing — a wrong guess here
  /// shows a Partner a confident, wrong instruction.
  AuthFailure _failureFor(ApiException error) => switch (error.kind) {
    ApiFailureKind.connection || ApiFailureKind.timeout => AuthFailure.network,
    // The only field this call sends is the phone number, so a validation
    // failure is always about the phone number.
    ApiFailureKind.validation => AuthFailure.invalidPhone,
    ApiFailureKind.rateLimited => AuthFailure.tooManyAttempts,

    // Not observed on this endpoint — a 422 here would be the server refusing
    // a well-formed request for a reason it has not documented, so it stays
    // unclassified rather than being given a confident wrong sentence.
    ApiFailureKind.rejected => AuthFailure.unknown,
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
