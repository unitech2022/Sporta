part of 'americano_detail_cubit.dart';

enum AmericanoDetailStatus { initial, loading, success, failure }

class AmericanoDetailState extends Equatable {
  const AmericanoDetailState({
    this.status = AmericanoDetailStatus.initial,
    this.americano,
    this.savingRoundId,
    this.joining = false,
    this.responding = false,
    this.error,
  });

  final AmericanoDetailStatus status;
  final AmericanoEntity? americano;

  /// Id of the round currently being saved (drives the per-round spinner).
  final int? savingRoundId;

  /// True while a join request is in flight (drives the join-button spinner).
  final bool joining;

  /// True while a partner-invite reply (accept/reject) is in flight.
  final bool responding;
  final String? error;

  AmericanoDetailState copyWith({
    AmericanoDetailStatus? status,
    AmericanoEntity? americano,
    int? savingRoundId,
    bool clearSaving = false,
    bool? joining,
    bool? responding,
    String? error,
  }) {
    return AmericanoDetailState(
      status: status ?? this.status,
      americano: americano ?? this.americano,
      savingRoundId: clearSaving ? null : (savingRoundId ?? this.savingRoundId),
      joining: joining ?? this.joining,
      responding: responding ?? this.responding,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    americano,
    savingRoundId,
    joining,
    responding,
    error,
  ];
}
