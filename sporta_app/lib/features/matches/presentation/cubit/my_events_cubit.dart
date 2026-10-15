import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../americano/data/americano_repository.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/match_repository.dart';
import '../../domain/entities/match_entity.dart';

part 'my_events_state.dart';

/// أي قائمة تعرضها صفحة «عرض الكل»: مبارياتي / الأمريكانو الخاص بي / بطولاتي.
enum MyEventsKind { match, americano, tournament }

/// صفحة «عرض الكل» لما أنشأه المستخدم أو شارك فيه — الحالية فقط، الأحدث
/// أولاً، مقسّمةً صفحات؛ ومع [finished] صفحة «المنتهية» (المنتهي والملغى).
/// المباريات في [MyEventsState.matches] والأمريكانو/البطولات في
/// [MyEventsState.events] بحسب [kind].
class MyEventsCubit extends Cubit<MyEventsState> {
  MyEventsCubit(
    this._matches,
    this._americano,
    this.kind, {
    this.finished = false,
  }) : super(const MyEventsState());

  final MatchRepository _matches;
  final AmericanoRepository _americano;
  final MyEventsKind kind;
  final bool finished;

  static const int _pageSize = 10;

  String? get _americanoKind => switch (kind) {
    MyEventsKind.match => null,
    MyEventsKind.americano => 'americano',
    MyEventsKind.tournament => 'tournament',
  };

  Future<void> load() async {
    emit(state.copyWith(status: MyEventsStatus.loading, error: null));
    try {
      emit(await _fetch(1, reset: true));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MyEventsStatus.failure, error: e.display));
    }
  }

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != MyEventsStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      emit(await _fetch(state.page + 1, reset: false));
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<MyEventsState> _fetch(int page, {required bool reset}) async {
    if (kind == MyEventsKind.match) {
      final p = await _matches.fetchMyMatches(
        page: page,
        pageSize: _pageSize,
        matchesOnly: true,
        newestFirst: true,
        activeOnly: !finished,
        finishedOnly: finished,
      );
      return state.copyWith(
        status: MyEventsStatus.success,
        matches: reset ? p.items : [...state.matches, ...p.items],
        page: p.page,
        hasMore: p.hasMore,
        loadingMore: false,
      );
    }
    final p = await _americano.fetchMine(
      page: page,
      pageSize: _pageSize,
      kind: _americanoKind,
      activeOnly: !finished,
      finishedOnly: finished,
    );
    return state.copyWith(
      status: MyEventsStatus.success,
      events: reset ? p.items : [...state.events, ...p.items],
      page: p.page,
      hasMore: p.hasMore,
      loadingMore: false,
    );
  }
}
