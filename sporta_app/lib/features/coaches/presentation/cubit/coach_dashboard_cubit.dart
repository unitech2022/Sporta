import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_dashboard.dart';

part 'coach_dashboard_state.dart';

/// Loads the signed-in coach's home dashboard stats.
class CoachDashboardCubit extends Cubit<CoachDashboardState> {
  CoachDashboardCubit(this._repository) : super(const CoachDashboardState());

  final CoachRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: CoachDashboardStatus.loading, error: null));
    try {
      final data = await _repository.fetchDashboard();
      emit(
        state.copyWith(status: CoachDashboardStatus.success, dashboard: data),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: CoachDashboardStatus.failure, error: e.display),
      );
    }
  }
}
