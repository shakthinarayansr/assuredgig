import 'worker_status.dart';

/// A piece of the profile the server is still waiting for.
///
/// The server sends these as strings in `missingFields`; an unrecognised one
/// becomes [unknown] and is **kept in the list**, never dropped. Dropping it
/// would make an incomplete profile look complete and strand a Partner on an
/// onboarding step the app cannot see.
enum ProfileRequirement { name, roles, homeArea, availability, photo, unknown }

/// The signed-in Partner, as the server sees them.
///
/// Nullable fields are nullable because the server sends `null` for them
/// before onboarding — not because they are optional forever. What is actually
/// required is [missingFields], and that is the server's answer, not a rule
/// this class re-derives.
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.phone,
    required this.status,
    required this.languageCode,
    required this.roles,
    required this.travelDistanceKm,
    required this.profileComplete,
    required this.missingFields,
    required this.hasAvailability,
    this.name,
    this.homeAreaLabel,
    this.homeLat,
    this.homeLng,
    this.profilePhotoKey,
  });

  final String id;

  /// E.164. PII — never goes in a log, a breadcrumb, or a crash report
  /// (NFR-07).
  final String phone;

  final String? name;
  final WorkerStatus status;

  /// `en` or `ta`. The server's record of the choice; the app's own locale is
  /// restored from disk before first render and the two are synced, not
  /// merged.
  final String languageCode;

  /// Role codes the Partner works. Empty until onboarding sets them.
  final List<String> roles;

  final String? homeAreaLabel;
  final double? homeLat;
  final double? homeLng;

  /// How far the Partner will travel. Server-held, so matching and the app
  /// agree on one number.
  final int travelDistanceKm;

  /// Whether an availability pattern exists (PROF-05/06). A flag, not the
  /// pattern: the server sends `null` today and its populated shape is not yet
  /// known, so modelling it would be inventing a contract.
  final bool hasAvailability;

  /// Storage key, not a URL. Resolving it to something displayable is a
  /// separate, presigned call.
  final String? profilePhotoKey;

  final bool profileComplete;
  final List<ProfileRequirement> missingFields;

  /// True when onboarding has somewhere to send the Partner.
  ///
  /// Reads the server's verdict *and* its list, because the two disagreeing is
  /// exactly the case worth being conservative about.
  bool get needsOnboarding => !profileComplete || missingFields.isNotEmpty;
}
