import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/api_endpoints.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// The server's reply to `GET /v1/workers/me`.
///
/// Field for field, including the ones that are `null` before onboarding. The
/// wire types are kept as they arrive — `status` and `missingFields` stay
/// strings here and become enums in `data/`, because the provider has no
/// business knowing what `PENDING_VETTING` means.
class WorkerProfileResponse {
  const WorkerProfileResponse({
    required this.id,
    required this.phone,
    required this.status,
    required this.languagePref,
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

  factory WorkerProfileResponse.fromJson(Map<String, dynamic> json) {
    final travel = json['travelDistanceKm'];
    return WorkerProfileResponse(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? '',
      languagePref: json['languagePref'] as String? ?? '',
      roles: _strings(json['roles']),
      travelDistanceKm: travel is num ? travel.toInt() : 0,
      profileComplete: json['profileComplete'] as bool? ?? false,
      missingFields: _strings(json['missingFields']),
      // Sent as `null` today. Its populated shape is not yet known, so this
      // records only that something is there — inventing a model for a payload
      // nobody has seen would be a contract the server never agreed to.
      hasAvailability: json['availability'] != null,
      name: json['name'] as String?,
      homeAreaLabel: json['homeAreaLabel'] as String?,
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      profilePhotoKey: json['profilePhotoKey'] as String?,
    );
  }

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const <String>[];

  final String id;
  final String phone;
  final String? name;
  final String status;
  final String languagePref;
  final List<String> roles;
  final String? homeAreaLabel;
  final double? homeLat;
  final double? homeLng;
  final int travelDistanceKm;
  final bool hasAvailability;
  final String? profilePhotoKey;
  final bool profileComplete;
  final List<String> missingFields;
}

/// Talks to the worker endpoints.
///
/// Hand-written for the same reason as `AuthApiProvider`, and deleted the same
/// day: TRD §3 wants this generated from an OpenAPI spec that does not exist
/// yet.
@lazySingleton
class WorkerApiProvider {
  const WorkerApiProvider(this._dio);

  final Dio _dio;

  /// Reads the signed-in Partner's profile.
  ///
  /// The bearer token is attached by the interceptor, not passed in — no
  /// caller above `sources/` holds a token to pass (NFR-05).
  ///
  /// Throws [ApiException]; `kind: unauthorized` (401 `UNAUTHENTICATED`) is the
  /// one worth handling, and the server sends it for a missing, malformed, or
  /// expired token alike.
  Future<WorkerProfileResponse> fetchMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AuthApis.profile,
        options: authenticated(),
      );
      return WorkerProfileResponse.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw error.asApiException;
    }
  }
}
