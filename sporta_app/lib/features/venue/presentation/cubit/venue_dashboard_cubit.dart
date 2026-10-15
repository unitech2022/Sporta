import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/venue_dashboard.dart';

part 'venue_dashboard_state.dart';

/// Loads the signed-in venue owner's home dashboard stats.
class VenueDashboardCubit extends Cubit<VenueDashboardState> {
  VenueDashboardCubit(this._repository) : super(const VenueDashboardState());

  final VenueRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: VenueDashboardStatus.loading, error: null));
    try {
      final data = await _repository.fetchDashboard();
      emit(
        state.copyWith(status: VenueDashboardStatus.success, dashboard: data),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: VenueDashboardStatus.failure, error: e.display),
      );
    }
  }
}
