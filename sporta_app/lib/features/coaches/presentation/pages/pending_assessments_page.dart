import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../level/domain/level_assessment_item.dart';
import '../../data/coach_repository.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/skeleton.dart';

/// Coach-facing screen: review pending level assessments (video uploads and
/// coach-requested) and assign a level (1..7).
class PendingAssessmentsPage extends StatefulWidget {
  const PendingAssessmentsPage({super.key});

  @override
  State<PendingAssessmentsPage> createState() => _PendingAssessmentsPageState();
}

class _PendingAssessmentsPageState extends State<PendingAssessmentsPage> {
  final _repo = getIt<CoachRepository>();

  List<LevelAssessmentItem> _items = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await _repo.fetchPendingAssessments();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    _loadingMore = true;
    try {
      final page = await _repo.fetchPendingAssessments(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Keep what's loaded; scrolling again retries.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _assign(LevelAssessmentItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<({int level, String? notes})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignSheet(playerName: item.playerName ?? ''),
    );
    if (result == null) return;
    try {
      await _repo.assignAssessment(item.id, result.level, result.notes);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم تحديد مستوى اللاعب'))),
      );
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.tr('طلبات تقييم المستوى')),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _loading
            ? const SkeletonList()
            : _items.isEmpty
            ? Center(
                child: Text(
                  context.tr('لا توجد طلبات حالياً'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: LoadMoreListener(
                  // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
                  onLoadMore: () {
                    _loadMore();
                  },
                  child: ListView.separated(
                    padding: context.safeBottom(
                      const EdgeInsets.all(AppSizes.pagePadding),
                    ),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.md),
                    itemBuilder: (_, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _tile(_items[i]);
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _tile(LevelAssessmentItem a) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.playerName ?? context.tr('لاعب'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(a.typeLabel, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (a.videoUrl != null) ...[
            const SizedBox(height: AppSizes.md),
            SelectableText(
              ApiEndpoints.fileUrl(a.videoUrl!),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _assign(a),
              icon: const Icon(Icons.grade_outlined),
              label: Text(context.tr('تحديد المستوى')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.playerName});

  final String playerName;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  int _level = 3;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.pagePadding,
          right: AppSizes.pagePadding,
          top: AppSizes.lg,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              AppSizes.lg +
              context.bottomSystemInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('تحديد مستوى %s').replaceAll('%s', widget.playerName),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              '${context.tr('المستوى')}: $_level',
              style: AppTextStyles.body,
            ),
            Slider(
              value: _level.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_level',
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _level = v.round()),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('ملاحظات (اختياري)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, (
                  level: _level,
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('confirm')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
