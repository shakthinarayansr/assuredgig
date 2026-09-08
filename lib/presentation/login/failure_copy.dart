import '../../core/constants/brand.dart';
import '../../domain/entities/auth_failure.dart';
import '../../l10n/app_localizations.dart';

/// The one place an [AuthFailure] becomes words.
///
/// The domain carries codes and the screen carries sentences — see
/// `ai_tools/memory/2026-09-08-state-carries-failure-codes-not-strings.md`.
/// Keeping the mapping here rather than inline means the phone step and the
/// code step cannot describe the same failure two different ways.
///
/// Every line names the **next action**, not the fault (CLAUDE.md §6). The
/// server's own `message` is never shown: it is English, written for
/// developers, and on this backend it is sometimes wrong.
extension AuthFailureCopy on AuthFailure {
  String message(AppL10n l10n) => switch (this) {
    AuthFailure.network => l10n.errorNetwork,
    AuthFailure.invalidPhone => l10n.errorInvalidPhone,
    AuthFailure.invalidOtp => l10n.errorInvalidOtp,
    AuthFailure.otpExpired => l10n.errorOtpExpired,
    AuthFailure.tooManyAttempts => l10n.errorTooManyAttempts,
    // AUTH-07 / LEG-01. Terminal, and the copy must not imply otherwise: no
    // "contact support", no appeal, no retry. An under-18 applicant who
    // believes a phone call changes this will make that call, and ops will
    // have to refuse it (PRD §4).
    AuthFailure.underAge => l10n.errorUnderAge(Brand.name),
    AuthFailure.accountUnavailable => l10n.errorAccountUnavailable,
    AuthFailure.sessionExpired => l10n.errorSessionExpired,
    AuthFailure.unknown => l10n.errorUnknown,
  };
}
