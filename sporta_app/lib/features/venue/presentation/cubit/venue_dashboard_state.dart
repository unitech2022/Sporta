part of 'venue_dashboard_cubit.dart';

enum VenueDashboardStatus { initial, loading, success, failure }

class VenueDashboardState extends Equatable {
  const VenueDashboardState({
    this.status = VenueDashboardStatus.initial,
    this.dashboard,
    this.error,
  });

  final VenueDashboardStatus status;
  final VenueDashboard? dashboard;
  final String? error;

  VenueDashboardState copyWith({
    VenueDashboardStatus? status,
    VenueDashboard? dashboard,
    String? error,
  }) {
    return VenueDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, error];
}
