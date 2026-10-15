import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/review_repository.dart';
import '../../domain/review_models.dart';

enum CourtReviewsStatus { loading, success, failure }

class CourtReviewsState extends Equatable {
  const CourtReviewsState({
    this.status = CourtReviewsStatus.loading,
    this.summary,
    this.reviews = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final CourtReviewsStatus status;
  final CourtRatingsSummary? summary;
  final List<ReviewItem> reviews;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String? error;

  CourtReviewsState copyWith({
    CourtReviewsStatus? status,
    CourtRatingsSummary? summary,
    List<ReviewItem>? reviews,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) => CourtReviewsState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    reviews: reviews ?? this.reviews,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    summary,
    reviews,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}

/// صفحة كل تقييمات ملعب: الملخّص + المراجعات مقسّمة صفحات.
class CourtReviewsCubit extends Cubit<CourtReviewsState> {
  CourtReviewsCubit(this._repo, this.courtId)
    : super(const CourtReviewsState());

  final ReviewRepository _repo;
  final int courtId;

  static const _pageSize = 15;

  Future<void> load() async {
    emit(state.copyWith(status: CourtReviewsStatus.loading));
    try {
      final s = await _repo.fetchCourtRatings(courtId, pageSize: _pageSize);
      emit(
        state.copyWith(
          status: CourtReviewsStatus.success,
          summary: s,
          reviews: s.reviews,
          page: s.page,
          hasMore: s.hasMore,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: CourtReviewsStatus.failure, error: e.display),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final s = await _repo.fetchCourtRatings(
        courtId,
        page: state.page + 1,
        pageSize: _pageSize,
      );
      emit(
        state.copyWith(
          reviews: [...state.reviews, ...s.reviews],
          page: s.page,
          hasMore: s.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }
}
