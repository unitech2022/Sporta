part of 'cup_detail_cubit.dart';

enum CupDetailStatus { initial, loading, success, failure }

class CupDetailState extends Equatable {
  const CupDetailState({
    this.status = CupDetailStatus.initial,
    this.tournament,
    this.busy = false,
    this.joining = false,
    this.savingFixtureId,
    this.error,
  });

  final CupDetailStatus status;
  final CupEntity? tournament;

  /// أي فعل في الطريق (انضمام/ردّ/بدء/تأجيل/إلغاء).
  final bool busy;
  final bool joining;

  /// المباراة التي تُحفظ نتيجتها الآن.
  final int? savingFixtureId;
  final String? error;

  CupDetailState copyWith({
    CupDetailStatus? status,
    CupEntity? tournament,
    bool? busy,
    bool? joining,
    int? savingFixtureId,
    bool clearSaving = false,
    String? error,
  }) => CupDetailState(
    status: status ?? this.status,
    tournament: tournament ?? this.tournament,
    busy: busy ?? this.busy,
    joining: joining ?? this.joining,
    savingFixtureId: clearSaving
        ? null
        : (savingFixtureId ?? this.savingFixtureId),
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    tournament,
    busy,
    joining,
    savingFixtureId,
    error,
  ];
}
