import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../../../core/network/paged.dart';
import '../../data/americano_repository.dart';
import '../../domain/entities/americano_entity.dart';

part 'americano_list_state.dart';

/// Loads the list of americano events for the americano/tournament tabs.
class AmericanoListCubit extends Cubit<AmericanoListState> {
  AmericanoListCubit(this._repository) : super(const AmericanoListState());

  final AmericanoRepository _repository;

  /// Server-side kind filter: 'americano' | 'tournament' | null (both).
  /// Set once via [load] and reused by [loadMore].
  String? _kind;

  /// هل يُجلب قسم «ما أنشأته/شاركت فيه» مع القائمة (للمسجّل فقط).
  bool _includeMine = false;

  /// كم عنصراً يُعرض في القسم قبل زر «عرض الكل».
  static const int minePreviewCount = 5;

  Future<void> load({
    bool isArabic = true,
    String? kind,
    bool? includeMine,
  }) async {
    _kind = kind ?? _kind;
    _includeMine = includeMine ?? _includeMine;
    emit(state.copyWith(status: AmericanoListStatus.loading, error: null));
    try {
      emit(await _fetchLists());
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: AmericanoListStatus.failure, error: e.display),
      );
    }
  }

  /// الصفحة الأولى من القائمة العامة وما يخصّني معاً — فشل الثاني وحده لا
  /// يُسقط الصفحة؛ يُعرض القسم فارغاً.
  Future<AmericanoListState> _fetchLists() async {
    final results = await Future.wait([
      _repository.fetchAll(kind: _kind),
      if (_includeMine)
        _repository
            .fetchMine(
              kind: _kind,
              pageSize: minePreviewCount,
              activeOnly: true,
            )
            .then<Paged<AmericanoEntity>?>((p) => p, onError: (_) => null),
    ]);
    final page = results[0]!;
    final mine = results.length > 1 ? results[1] : null;
    return state.copyWith(
      status: AmericanoListStatus.success,
      items: page.items,
      mine: mine?.items ?? const [],
      mineTotal: mine?.total ?? 0,
      page: page.page,
      hasMore: page.hasMore,
      loadingMore: false,
    );
  }

  /// الانضمام من بطاقة القائمة مباشرةً (الخادم يضع اللاعب في أول مقعد شاغر).
  /// يعيد رسالة الخطأ عند الفشل وnull عند النجاح. بعده يُعاد جلب القسمين
  /// بصمت (بلا هيكل تحميل): الحدث صار «يخصّني» فينتقل إلى قسمه.
  Future<String?> join(int id) async {
    emit(state.copyWith(joiningId: id));
    try {
      final updated = await _repository.join(id);
      emit(
        state.copyWith(
          items: state.items
              .map((a) => a.id == updated.id ? updated : a)
              .toList(),
          clearJoining: true,
        ),
      );
      try {
        emit(await _fetchLists());
      } on ApiException {
        // العنصر محدّث محلياً؛ القسم يلحق عند التحديث التالي.
      }
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(clearJoining: true));
      return e.display;
    }
  }

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != AmericanoListStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchAll(
        page: state.page + 1,
        kind: _kind,
      );
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
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
}
