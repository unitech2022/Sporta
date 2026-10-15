import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../../../core/network/paged.dart';
import '../../data/match_repository.dart';
import '../../domain/entities/match_entity.dart';

part 'matches_state.dart';

/// Drives the open-matches list: loading and joining. Networking lives in
/// [MatchRepository].
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._repository) : super(const MatchesState());

  final MatchRepository _repository;

  /// هل يُجلب قسم «مبارياتي» مع القائمة (للمسجّل فقط — الزائر لا يملك
  /// مباريات والنقطة تتطلب توكناً). يُحفظ من أول [loadMatches] لإعادة التحميل.
  bool _includeMine = false;

  /// كم مباراة تُعرض في قسم «مبارياتي» قبل زر «عرض الكل».
  static const int minePreviewCount = 5;

  Future<void> loadMatches({bool isArabic = true, bool? includeMine}) async {
    _includeMine = includeMine ?? _includeMine;
    emit(state.copyWith(status: MatchesStatus.loading, error: null));
    try {
      emit(await _fetchLists());
    } on ApiException catch (e) {
      emit(state.copyWith(status: MatchesStatus.failure, error: e.display));
    }
  }

  /// الصفحة الأولى من القائمة العامة ومبارياتي الحالية معاً — فشل «مبارياتي»
  /// وحده لا يُسقط الصفحة؛ يُعرض القسم فارغاً.
  Future<MatchesState> _fetchLists() async {
    final results = await Future.wait([
      _repository.fetchMatches(),
      if (_includeMine)
        _repository
            .fetchMyMatches(
              pageSize: minePreviewCount,
              activeOnly: true,
              matchesOnly: true,
              newestFirst: true,
            )
            .then<Paged<MatchEntity>?>((p) => p, onError: (_) => null),
    ]);
    final page = results[0]!;
    final mine = results.length > 1 ? results[1] : null;
    return state.copyWith(
      status: MatchesStatus.success,
      matches: page.items,
      mine: mine?.items ?? const [],
      mineTotal: mine?.total ?? 0,
      page: page.page,
      hasMore: page.hasMore,
      loadingMore: false,
    );
  }

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != MatchesStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchMatches(page: state.page + 1);
      emit(
        state.copyWith(
          matches: [...state.matches, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Invites [userIds] to [matchId] one by one; replaces the match in the list.
  /// Returns an error message on the first failure (null on full success).
  Future<String?> invitePlayers(
    int matchId,
    List<int> userIds, {
    bool isArabic = true,
  }) async {
    MatchEntity? updated;
    try {
      for (final id in userIds) {
        updated = await _repository.invitePlayer(matchId, id);
      }
      if (updated != null) {
        final m = updated;
        emit(
          state.copyWith(
            matches: state.matches.map((x) => x.id == m.id ? m : x).toList(),
          ),
        );
      }
      return null;
    } on ApiException catch (e) {
      // Reflect any partial success, then report the error.
      if (updated != null) {
        final m = updated;
        emit(
          state.copyWith(
            matches: state.matches.map((x) => x.id == m.id ? m : x).toList(),
          ),
        );
      }
      return e.display;
    }
  }

  /// Joins [matchId]; on success replaces the match in the list. Returns an
  /// error message on failure (null on success) so the UI can surface it.
  Future<String?> joinMatch(int matchId, {bool isArabic = true}) async {
    emit(state.copyWith(joiningId: matchId, clearJoining: false));
    try {
      final updated = await _repository.joinMatch(matchId);
      final matches = state.matches
          .map((m) => m.id == updated.id ? updated : m)
          .toList();
      emit(state.copyWith(matches: matches, clearJoining: true));
      // صارت من «مبارياتي» (طلب معلّق) فتُستبعد من القائمة العامة — يُعاد
      // جلب القسمين بصمت كي تظهر في قسمها بدل أن تختفي.
      if (_includeMine) {
        try {
          emit(await _fetchLists());
        } on ApiException {
          // القائمة المحلية محدّثة أصلاً؛ لا بأس بتأخّر القسم حتى التحديث التالي.
        }
      }
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearJoining: true));
      return e.display;
    }
  }
}
