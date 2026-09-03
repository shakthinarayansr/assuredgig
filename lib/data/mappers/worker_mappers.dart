import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_status.dart';

/// Wire strings to domain enums, in one place.
///
/// The mapping lives here rather than in the entities because the wire
/// vocabulary is the server's, and the domain should not have to change its
/// own types the day the server renames a constant.
extension WorkerStatusWire on WorkerStatus {
  /// Only `PENDING_VETTING` is confirmed against the live backend; the rest
  /// are the plausible vocabulary. Everything unrecognised is [unknown], which
  /// is never treated as eligible — the safe direction to be wrong in.
  static WorkerStatus fromWire(String wire) => switch (wire.toUpperCase()) {
    'PENDING_VETTING' || 'PENDING' => WorkerStatus.pendingVetting,
    'ACTIVE' || 'VERIFIED' => WorkerStatus.active,
    'SUSPENDED' ||
    'BLOCKED' ||
    'REJECTED' ||
    'DELETED' => WorkerStatus.inactive,
    _ => WorkerStatus.unknown,
  };
}

extension ProfileRequirementWire on ProfileRequirement {
  /// `name`, `roles` and `homeArea` are confirmed. An unrecognised requirement
  /// maps to [ProfileRequirement.unknown] and stays in the list: a dropped
  /// requirement would read as a complete profile.
  static ProfileRequirement fromWire(String wire) => switch (wire) {
    'name' => ProfileRequirement.name,
    'roles' => ProfileRequirement.roles,
    'homeArea' => ProfileRequirement.homeArea,
    'availability' => ProfileRequirement.availability,
    'photo' || 'profilePhoto' => ProfileRequirement.photo,
    _ => ProfileRequirement.unknown,
  };
}
