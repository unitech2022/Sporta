import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/paged.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/wallet_repository.dart';
import '../../domain/entities/wallet_entity.dart';

part 'wallet_state.dart';

/// Loads the wallet (balance + transactions) for the wallet screen.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repository) : super(const WalletState());

  final WalletRepository _repository;

  static const _pageSize = 20;

  /// Drops everything back to the initial state. Called on logout: this cubit
  /// is an app-wide singleton, so without it the next account would briefly
  /// see the previous account's balance and transactions.
  void reset() => emit(const WalletState());

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: WalletStatus.loading, error: null));
    try {
      // Balance + first page of transactions in parallel.
      final results = await Future.wait([
        _repository.fetchWallet(),
        _repository.fetchTransactions(page: 1, pageSize: _pageSize),
      ]);
      final wallet = results[0] as WalletEntity;
      final firstPage = results[1] as Paged<WalletTransactionEntity>;
      emit(state.copyWith(
        status: WalletStatus.success,
        wallet: wallet,
        transactions: firstPage.items,
        txPage: 1,
        txHasMore: firstPage.hasMore,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: WalletStatus.failure,
        error: e.display,
      ));
    }
  }

  /// Appends the next page of transactions (infinite scroll). No-op while a
  /// page is already loading or when the list is exhausted.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.txHasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repository.fetchTransactions(
          page: state.txPage + 1, pageSize: _pageSize);
      emit(state.copyWith(
        transactions: [...state.transactions, ...next.items],
        txPage: next.page,
        txHasMore: next.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // Keep what we have; allow a retry on the next scroll.
      emit(state.copyWith(loadingMore: false));
    }
  }
}
