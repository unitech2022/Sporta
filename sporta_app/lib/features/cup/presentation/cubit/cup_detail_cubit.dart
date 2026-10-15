import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../americano/data/americano_repository.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/cup_repository.dart';
import '../../domain/entities/cup_entity.dart';
import '../../../matches/domain/entities/withdrawal.dart';

part 'cup_detail_state.dart';

/// تحميل بطولة إقصائية وتنفيذ أفعالها: الانضمام لفريق، الردّ على دعوة
/// الشريك، تسجيل نتيجة، وإجراءات المنظّم (بدء/تأجيل/إلغاء).
class CupDetailCubit extends Cubit<CupDetailState> {
  CupDetailCubit(this._repository, this._americano)
    : super(const CupDetailState());

  final CupRepository _repository;
  final AmericanoRepository _americano;

  Future<void> load(int id) async {
    emit(state.copyWith(status: CupDetailStatus.loading, error: null));
    try {
      final t = await _repository.fetchById(id);
      emit(state.copyWith(status: CupDetailStatus.success, tournament: t));
    } on ApiException catch (e) {
      emit(state.copyWith(status: CupDetailStatus.failure, error: e.display));
    }
  }

  /// كل الأفعال تعيد رسالة خطأ عند الفشل، وnull عند النجاح.
  Future<String?> _run(
    Future<void> Function() action, {
    bool joining = false,
  }) async {
    emit(state.copyWith(busy: true, joining: joining));
    try {
      await action();
      final t = await _repository.fetchById(state.tournament!.id);
      emit(state.copyWith(tournament: t, busy: false, joining: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, joining: false));
      return e.display;
    }
  }

  /// [team] null = يضعه الخادم تلقائياً في أول مقعد شاغر.
  Future<String?> joinTeam(int? team, {int? partnerId}) => _run(
    () =>
        _americano.join(state.tournament!.id, team: team, partnerId: partnerId),
    joining: true,
  );

  /// عضو معتمد يدعو زميلاً إلى فريقه (مقعده الشاغر).
  Future<String?> invitePartner(int userId) =>
      _run(() => _americano.invitePartner(state.tournament!.id, userId));

  /// المنظّم يقبل/يرفض طلب انضمام لاعب.
  Future<String?> respondToJoinRequest(int userId, bool approve) => _run(
    () => _americano.respondToJoinRequest(
      state.tournament!.id,
      userId: userId,
      approve: approve,
    ),
  );

  /// انسحاب المستخدم (أو إلغاء طلب انضمامه): النتيجة عند النجاح، أو الخطأ.
  Future<(WithdrawalOutcome?, String?)> withdraw() async {
    WithdrawalOutcome? outcome;
    final error = await _run(() async {
      outcome = (await _americano.withdraw(state.tournament!.id)).$1;
    });
    return (error == null ? outcome : null, error);
  }

  /// المنظّم يقبل/يرفض طلب انسحاب متأخراً.
  Future<String?> respondToWithdrawal(int userId, bool approve) => _run(
    () => _americano.respondToWithdrawal(
      state.tournament!.id,
      userId: userId,
      approve: approve,
    ),
  );

  Future<String?> respondToInvite(bool accept) =>
      _run(() => _americano.respondToInvite(state.tournament!.id, accept));

  Future<String?> submitScore(int fixtureId, int t1, int t2) async {
    emit(state.copyWith(savingFixtureId: fixtureId));
    try {
      final t = await _repository.submitScore(
        fixtureId: fixtureId,
        team1Score: t1,
        team2Score: t2,
      );
      emit(state.copyWith(tournament: t, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  Future<String?> resolveScore(int fixtureId, int t1, int t2) async {
    emit(state.copyWith(savingFixtureId: fixtureId));
    try {
      final t = await _repository.resolveScore(
        fixtureId: fixtureId,
        team1Score: t1,
        team2Score: t2,
      );
      emit(state.copyWith(tournament: t, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  /// المنظّم يسجّل النتيجة نهائيةً بعد موعد المباراة، أو فوزاً بالانسحاب.
  Future<String?> recordScore(
    int fixtureId,
    int t1,
    int t2, {
    bool walkover = false,
  }) async {
    emit(state.copyWith(savingFixtureId: fixtureId));
    try {
      final t = await _repository.recordScore(
        fixtureId: fixtureId,
        team1Score: t1,
        team2Score: t2,
        walkover: walkover,
      );
      emit(state.copyWith(tournament: t, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  Future<String?> respondScore(int fixtureId, bool accept) async {
    emit(state.copyWith(savingFixtureId: fixtureId));
    try {
      final t = await _repository.respondScore(
        fixtureId: fixtureId,
        accept: accept,
        seen: state.tournament?.fixtures
            .where((f) => f.id == fixtureId)
            .firstOrNull
            ?.pendingResult,
      );
      emit(state.copyWith(tournament: t, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  Future<String?> renameTeam(int team, String name) =>
      _run(() => _repository.renameTeam(state.tournament!.id, team, name));

  Future<String?> startWithCurrent() =>
      _run(() => _repository.startWithCurrent(state.tournament!.id));

  Future<String?> postpone(DateTime newStart) =>
      _run(() => _repository.postpone(state.tournament!.id, newStart));

  Future<String?> cancel() =>
      _run(() => _repository.cancel(state.tournament!.id));
}
