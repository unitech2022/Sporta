part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.txPage = 0,
    this.txHasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final WalletStatus status;
  final WalletEntity? wallet;

  /// Paged transaction history (accumulated across pages).
  final List<WalletTransactionEntity> transactions;
  final int txPage;
  final bool txHasMore;
  final bool loadingMore;
  final String? error;

  WalletState copyWith({
    WalletStatus? status,
    WalletEntity? wallet,
    List<WalletTransactionEntity>? transactions,
    int? txPage,
    bool? txHasMore,
    bool? loadingMore,
    String? error,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      txPage: txPage ?? this.txPage,
      txHasMore: txHasMore ?? this.txHasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, wallet, transactions, txPage, txHasMore, loadingMore, error];
}
