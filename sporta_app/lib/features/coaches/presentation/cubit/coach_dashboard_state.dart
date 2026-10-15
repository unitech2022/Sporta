part of 'coach_dashboard_cubit.dart';

enum CoachDashboardStatus { initial, loading, success, failure }

class CoachDashboardState extends Equatable {
  const CoachDashboardState({
    this.status = CoachDashboardStatus.initial,
    this.dashboard,
    this.error,
  });

  final CoachDashboardStatus status;
  final CoachDashboard? dashboard;
  final String? error;

  CoachDashboardState copyWith({
    CoachDashboardStatus? status,
    CoachDashboard? dashboard,
    String? error,
  }) {
    return CoachDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, error];
}
