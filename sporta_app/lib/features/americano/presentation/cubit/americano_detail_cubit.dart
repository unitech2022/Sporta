import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/americano_repository.dart';
import '../../domain/entities/americano_entity.dart';
import '../../../../core/di/service_locator.dart';
import '../../../matches/data/match_repository.dart';
import '../../../matches/domain/entities/withdrawal.dart';

part 'americano_detail_state.dart';

/// Loads one americano and records round scores (refreshing standings).
class AmericanoDetailCubit extends Cubit<AmericanoDetailState> {
  AmericanoDetailCubit(this._repository) : super(const AmericanoDetailState());

  final AmericanoRepository _repository;

  Future<void> load(int id, {bool isArabic = true}) async {
    emit(state.copyWith(status: AmericanoDetailStatus.loading, error: null));
    try {
      final americano = await _repository.fetchById(id);
      emit(
        state.copyWith(
          status: AmericanoDetailStatus.success,
          americano: americano,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: AmericanoDetailStatus.failure, error: e.display),
      );
    }
  }

  /// Joins the americano; returns an error message on failure (null on success).
  Future<String?> join(
    int id, {
    int? team,
    int? partnerId,
    bool isArabic = true,
  }) async {
    emit(state.copyWith(joining: true));
    try {
      final americano = await _repository.join(
        id,
        team: team,
        partnerId: partnerId,
      );
      emit(state.copyWith(americano: americano, joining: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(joining: false));
      return e.display;
    }
  }

  /// Teams: invite a friend as partner. Returns an error message on failure.
  Future<String?> invitePartner(
    int id,
    int userId, {
    bool isArabic = true,
  }) async {
    emit(state.copyWith(joining: true));
    try {
      final americano = await _repository.invitePartner(id, userId);
      emit(state.copyWith(americano: americano, joining: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(joining: false));
      return e.display;
    }
  }

  /// Accept/decline a pending partner invite. Returns an error message on failure.
  Future<String?> respondToInvite(
    int id,
    bool accept, {
    bool isArabic = true,
  }) async {
    emit(state.copyWith(responding: true));
    try {
      final americano = await _repository.respondToInvite(id, accept);
      emit(state.copyWith(americano: americano, responding: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(responding: false));
      return e.display;
    }
  }

  /// المنظّم يقبل/يرفض طلب انضمام؛ يعيد رسالة الخطأ عند الفشل.
  Future<String?> respondToJoinRequest(int id, int userId, bool approve) async {
    emit(state.copyWith(responding: true));
    try {
      final americano = await _repository.respondToJoinRequest(
        id,
        userId: userId,
        approve: approve,
      );
      emit(state.copyWith(americano: americano, responding: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(responding: false));
      return e.display;
    }
  }

  /// انسحاب المستخدم (أو إلغاء طلب انضمامه). يعيد النتيجة عند النجاح، ورسالة
  /// الخطأ عند الفشل — أحدهما فقط.
  Future<(WithdrawalOutcome?, String?)> withdraw(int id) async {
    emit(state.copyWith(responding: true));
    try {
      final (outcome, americano) = await _repository.withdraw(id);
      emit(state.copyWith(americano: americano, responding: false));
      return (outcome, null);
    } on ApiException catch (e) {
      emit(state.copyWith(responding: false));
      return (null, e.display);
    }
  }

  /// المنظّم يقبل/يرفض طلب انسحاب متأخراً؛ يعيد رسالة الخطأ عند الفشل.
  Future<String?> respondToWithdrawal(int id, int userId, bool approve) async {
    emit(state.copyWith(responding: true));
    try {
      final americano = await _repository.respondToWithdrawal(
        id,
        userId: userId,
        approve: approve,
      );
      emit(state.copyWith(americano: americano, responding: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(responding: false));
      return e.display;
    }
  }

  /// صاحب الملعب يلغي الحدث الذي يستضيفه: تُردّ حصص المسجّلين وتُخصم منه.
  /// الإلغاء يقع على المباراة نفسها، فيُنادى بمعرّفها ثم يُعاد تحميل الأمريكانو.
  Future<String?> cancelHosted(int americanoId, int matchId) async {
    emit(state.copyWith(responding: true));
    try {
      await getIt<MatchRepository>().cancelHostedMatch(matchId);
      final americano = await _repository.fetchById(americanoId);
      emit(state.copyWith(americano: americano, responding: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(responding: false));
      return e.display;
    }
  }

  /// Submits a round score; returns an error message on failure (null on success).
  Future<String?> submitScore({
    required int roundId,
    required int team1Score,
    required int team2Score,
    bool isArabic = true,
  }) async {
    emit(state.copyWith(savingRoundId: roundId, clearSaving: false));
    try {
      final americano = await _repository.submitRoundScore(
        roundId: roundId,
        team1Score: team1Score,
        team2Score: team2Score,
      );
      emit(state.copyWith(americano: americano, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  /// المنظّم يحسم خلافاً على نتيجة جولة؛ يعيد رسالة الخطأ عند الفشل.
  Future<String?> resolveScore({
    required int roundId,
    required int team1Score,
    required int team2Score,
  }) async {
    emit(state.copyWith(savingRoundId: roundId, clearSaving: false));
    try {
      final americano = await _repository.resolveRoundScore(
        roundId: roundId,
        team1Score: team1Score,
        team2Score: team2Score,
      );
      emit(state.copyWith(americano: americano, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }

  /// تأكيد/رفض نتيجة جولة مقترحة؛ يعيد رسالة الخطأ عند الفشل.
  Future<String?> respondScore({
    required int roundId,
    required bool accept,
  }) async {
    emit(state.copyWith(savingRoundId: roundId, clearSaving: false));
    try {
      final americano = await _repository.respondRoundScore(
        roundId: roundId,
        accept: accept,
        seen: state.americano?.rounds
            .where((r) => r.id == roundId)
            .firstOrNull
            ?.pendingResult,
      );
      emit(state.copyWith(americano: americano, clearSaving: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearSaving: true));
      return e.display;
    }
  }
}
