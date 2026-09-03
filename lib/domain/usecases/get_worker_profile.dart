import '../entities/auth_failure.dart';
import '../entities/worker_profile.dart';

/// Reads the signed-in Partner's profile (`GET /v1/workers/me`).
///
/// Throws [AuthException] — [AuthFailure.sessionExpired] when the server
/// refuses the token, which is the caller's cue to send the Partner back to
/// login rather than to show an error.
///
/// **Not yet cache-first.** CLAUDE.md §4 requires reads to return cached data
/// immediately and refresh behind it; that needs the Drift cache from build
/// phase 2, which does not exist yet. This hits the network every call, and
/// the seam is here: when the cache lands, this implementation changes and no
/// caller does.
abstract interface class GetWorkerProfile {
  Future<WorkerProfile> call();
}
