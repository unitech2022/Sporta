part of 'manage_venues_cubit.dart';

enum ManageVenuesStatus { initial, loading, success, failure }

class ManageVenuesState extends Equatable {
  const ManageVenuesState({
    this.status = ManageVenuesStatus.initial,
    this.venues = const [],
    this.error,
  });

  final ManageVenuesStatus status;
  final List<OwnerVenue> venues;
  final String? error;

  ManageVenuesState copyWith({
    ManageVenuesStatus? status,
    List<OwnerVenue>? venues,
    String? error,
  }) {
    return ManageVenuesState(
      status: status ?? this.status,
      venues: venues ?? this.venues,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, venues, error];
}
