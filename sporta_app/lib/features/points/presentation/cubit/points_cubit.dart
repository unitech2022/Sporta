import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/points_repository.dart';
import '../../domain/entities/points_entity.dart';

part 'points_state.dart';

/// Loads the loyalty-points summary + ledger and performs redemptions.
class PointsCubit extends Cubit<PointsState> {
  PointsCubit(this._repository) : super(const PointsState());

  final PointsRepository _repository;

  static const _pageSize = 20;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: PointsStatus.loading, error: null));
    try {
      final (summary, txs) =
          await _repository.fetchSummary(page: 1, pageSize: _pageSize);
      emit(state.copyWith(
        status: PointsStatus.success,
        summary: summary,
        transactions: txs.items,
        txPage: 1,
        txHasMore: txs.hasMore,
        loadingMore: false,
      ));
      // سُلَّم المستويات تكميلي: فشله لا يُسقط الصفحة.
      try {
        final levels = await _repository.fetchLevels();
        emit(state.copyWith(levels: levels));
      } on ApiException {
        // تُعرض الصفحة بلا السُّلَّم.
      }
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PointsStatus.failure,
        error: e.display,
      ));
    }
  }

  /// Appends the next ledger page (infinite scroll).
  Future<void> loadMore() async {
    if (state.loadingMore || !state.txHasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final (_, next) = await _repository.fetchSummary(
          page: state.txPage + 1, pageSize: _pageSize);
      emit(state.copyWith(
        transactions: [...state.transactions, ...next.items],
        txPage: next.page,
        txHasMore: next.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Redeems [points] into wallet credit. Returns true on success.
  Future<bool> redeem(int points, {bool isArabic = true}) async {
    emit(state.copyWith(redeeming: true, error: null));
    try {
      final (summary, txs) = await _repository.redeem(points);
      emit(state.copyWith(
        status: PointsStatus.success,
        summary: summary,
        transactions: txs.items,
        txPage: 1,
        txHasMore: txs.hasMore,
        redeeming: false,
      ));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(redeeming: false, error: e.display));
      return false;
    }
  }
}
