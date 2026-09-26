import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/auth_failure.dart';
import '../../../domain/usecases/get_worker_profile.dart';

part 'partner_header_cubit.freezed.dart';

/// Who is signed in, for the app bar: a name and, later, a photo.
///
/// A failed read is not an error the header shows — the avatar falls back to
/// a generic mark and still opens the profile. The one failure that matters is
/// [AuthFailure.sessionExpired], which the shell turns into a trip to login.
@freezed
abstract class PartnerHeaderState with _$PartnerHeaderState {
  const factory PartnerHeaderState({
    @Default(true) bool loading,

    /// Trimmed, and null rather than empty — the server sends `null` before
    /// onboarding sets it.
    String? name,

    AuthFailure? failure,
  }) = _PartnerHeaderState;
}

@injectable
class PartnerHeaderCubit extends Cubit<PartnerHeaderState> {
  PartnerHeaderCubit(this._getProfile) : super(const PartnerHeaderState());

  final GetWorkerProfile _getProfile;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: null));
    try {
      final profile = await _getProfile();
      if (isClosed) return;
      final name = profile.name?.trim();
      emit(
        PartnerHeaderState(
          loading: false,
          name: name == null || name.isEmpty ? null : name,
        ),
      );
    } on AuthException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: error.failure));
    }
  }
}
