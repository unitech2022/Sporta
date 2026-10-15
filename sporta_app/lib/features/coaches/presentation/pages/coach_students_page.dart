import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_student_entity.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// إدارة الطلاب — the coach's students, aggregated from paid training
/// sessions: how many sessions each played, total spent, and when last seen.
class CoachStudentsPage extends StatefulWidget {
  const CoachStudentsPage({super.key});

  @override
  State<CoachStudentsPage> createState() => _CoachStudentsPageState();
}

class _CoachStudentsPageState extends State<CoachStudentsPage> {
  final _repo = getIt<CoachRepository>();
  final _scroll = ScrollController();

  final List<CoachStudentEntity> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;

  static List<String> get _monthsAr => [
    trg('يناير'),
    trg('فبراير'),
    trg('مارس'),
    trg('أبريل'),
    trg('مايو'),
    trg('يونيو'),
    trg('يوليو'),
    trg('أغسطس'),
    trg('سبتمبر'),
    trg('أكتوبر'),
    trg('نوفمبر'),
    trg('ديسمبر'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
        _initialLoading = true;
      }
    });
    try {
      final res = await _repo.fetchStudents(page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page += 1;
        _loading = false;
        _initialLoading = false;
      });
      _fillIfShort();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
  }

  /// التحميل التالي يبدأ مع التمرير، فإن لم تملأ الدفعة الشاشة (شاشة طويلة
  /// أو تابلت) لا يمكن التمرير ولا تُحمَّل البقية — فنجلب التالية فوراً.
  void _fillIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || _loading || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 200) _load();
    });
  }

  String _dateLabel(DateTime d) => '${d.day} ${_monthsAr[d.month - 1]}';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.substring(0, 1)).join('.');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('إدارة الطلاب')),
        ),
        body: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_initialLoading) {
      return const SkeletonList();
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          context.tr('لا يوجد طلاب بعد'),
          style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _tile(context, _items[i]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, CoachStudentEntity s) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NetworkCircleAvatar(
            imageUrl: s.avatarUrl,
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
                    _initials(s.playerName),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.playerName,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.sessionsCount} ${context.tr('حصة')} · ${context.tr('آخر حصة')} ${_dateLabel(s.lastSessionAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            context.trArgs('{p0} ر.س', {'p0': money(s.totalSpent)}),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
