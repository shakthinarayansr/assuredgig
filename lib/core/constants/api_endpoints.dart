/// Build-time backend coordinates.
///
/// The *base URL* is a constant on purpose — it identifies the environment and
/// cannot be fetched from the environment it identifies. Everything the config
/// endpoint owns (radii, windows, thresholds, wage floors, feature flags) does
/// **not** belong here (NFR-08, NFR-09, CLAUDE.md §2 principle 4).
///
/// Lives under `core/` so every layer may import it: the convention checker
/// governs imports by top-level directory, and a file sitting loose in `lib/`
/// is importable from nowhere.
class Constants {
  static const String appUrl = "https://assuredgig-backend-6jox.onrender.com";
}

/// Paths, relative to [Constants.appUrl].
class AuthApis {
  static const String sendOtp = "/v1/auth/otp/request";
  static const String verifyOtp = "/v1/auth/otp/verify";
  static const String profile = "/v1/workers/me";
}
