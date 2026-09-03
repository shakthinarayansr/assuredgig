import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/usecases/get_worker_profile.dart';
import '../../sources/api/api_exception.dart';
import '../../sources/api/worker_api_provider.dart';
import '../mappers/worker_mappers.dart';

/// Binds [GetWorkerProfile] to the live backend.
///
/// When the Drift cache lands (build phase 2), the cache-first read belongs
/// here — emit from disk, refresh behind it — and no caller changes.
@Injectable(as: GetWorkerProfile)
class GetWorkerProfileFromApi implements GetWorkerProfile {
  const GetWorkerProfileFromApi(this._api);

  final WorkerApiProvider _api;

  @override
  Future<WorkerProfile> call() async {
    try {
      return _toEntity(await _api.fetchMe());
    } on ApiException catch (error) {
      throw AuthException(_failureFor(error), retryAfter: error.retryAfter);
    }
  }

  WorkerProfile _toEntity(WorkerProfileResponse dto) => WorkerProfile(
    id: dto.id,
    phone: dto.phone,
    name: dto.name,
    status: WorkerStatusWire.fromWire(dto.status),
    languageCode: dto.languagePref,
    roles: dto.roles,
    homeAreaLabel: dto.homeAreaLabel,
    homeLat: dto.homeLat,
    homeLng: dto.homeLng,
    travelDistanceKm: dto.travelDistanceKm,
    hasAvailability: dto.hasAvailability,
    profilePhotoKey: dto.profilePhotoKey,
    profileComplete: dto.profileComplete,
    missingFields: dto.missingFields
        .map(ProfileRequirementWire.fromWire)
        .toList(growable: false),
  );

  AuthFailure _failureFor(ApiException error) => switch (error.kind) {
    ApiFailureKind.connection || ApiFailureKind.timeout => AuthFailure.network,

    // 401 UNAUTHENTICATED. Missing, malformed and expired all arrive as this
    // one code, so the client cannot distinguish "refresh" from "signed out"
    // and takes the safe reading: back to login.
    ApiFailureKind.unauthorized => switch (error.code) {
      'ACCOUNT_BLOCKED' || 'ACCOUNT_DELETED' => AuthFailure.accountUnavailable,
      _ => AuthFailure.sessionExpired,
    },

    ApiFailureKind.rateLimited => AuthFailure.tooManyAttempts,
    ApiFailureKind.validation ||
    ApiFailureKind.rejected ||
    ApiFailureKind.server ||
    ApiFailureKind.notFound ||
    ApiFailureKind.unexpected => AuthFailure.unknown,
  };
}
