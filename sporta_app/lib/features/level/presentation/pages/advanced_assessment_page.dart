import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/domain/entities/coach_entity.dart';
import '../../data/level_repository.dart';
import '../../domain/level_assessment_item.dart';
import '../../../../core/utils/system_insets.dart';

/// مفتاح إظهار «التقييم المتقدم للمستوى» — **مخفيّ بطلب المستخدم (2026-08-12)**.
///
/// كل مدخل يقود إلى [AdvancedAssessmentPage] محجوب بهذا المفتاح: بانر «تقييم
/// مستوى عند مدرب معتمد» في صفحة المدربين، وزر «أو قيّم مستواك بالفيديو أو عبر
/// مدرب» في التقييم الذاتي. الصفحة نفسها ومسارات الـ API (`/players/level-
/// assessment/video` و`/coach`) باقية كما هي — اجعله `true` لإعادة الإظهار.
const bool kAdvancedAssessmentEnabled = false;

/// Advanced level assessment: upload a video (path 2) or request a coach (path 3),
/// and track the status of submitted requests.
class AdvancedAssessmentPage extends StatefulWidget {
  const AdvancedAssessmentPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AdvancedAssessmentPage> createState() => _AdvancedAssessmentPageState();
}

class _AdvancedAssessmentPageState extends State<AdvancedAssessmentPage> {
  final _levelRepo = getIt<LevelRepository>();
  final _coachRepo = getIt<CoachRepository>();

  List<LevelAssessmentItem> _items = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _levelRepo.fetchMyAssessments();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadVideo() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _levelRepo.submitVideo(picked.path);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم رفع الفيديو — بانتظار مراجعة مدرب'))),
      );
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCoach() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    List<CoachEntity> coaches;
    try {
      // Coach picker: fetch one large page (max the API allows).
      coaches = (await _coachRepo.fetchCoaches(pageSize: 100)).items;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
      return;
    }
    if (!mounted) return;
    final coach = await showModalBottomSheet<CoachEntity>(
      context: context,
      builder: (_) => Directionality(
        textDirection: Directionality.of(context),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: Text(context.tr('اختر مدربًا لتقييم مستواك')),
              ),
              for (final c in coaches)
                ListTile(
                  leading: const Icon(Icons.sports, color: AppColors.primary),
                  title: Text(c.name),
                  subtitle: Text(c.location),
                  onTap: () => Navigator.pop(context, c),
                ),
            ],
          ),
        ),
      ),
    );
    if (coach == null) return;
    setState(() => _busy = true);
    try {
      await _levelRepo.requestCoach(coach.numericId);
      messenger.showSnackBar(
        SnackBar(content: Text(context.trArgs('تم إرسال طلب التقييم إلى {p0}', {'p0': coach.name}))),
      );
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const SkeletonList(itemCount: 4)
                  : ListView(
                      padding: context.safeBottom(
                          const EdgeInsets.all(AppSizes.pagePadding)),
                      children: [
                        _methodCard(
                          icon: Icons.videocam_outlined,
                          title: context.tr('تقييم بالفيديو'),
                          subtitle: context.tr('ارفع فيديو لأدائك ليراجعه مدرب معتمد'),
                          onTap: _busy ? null : _uploadVideo,
                        ),
                        const SizedBox(height: AppSizes.md),
                        _methodCard(
                          icon: Icons.person_search_outlined,
                          title: context.tr('تقييم عبر مدرب'),
                          subtitle: context.tr('اطلب من مدرب تقييم مستواك'),
                          onTap: _busy ? null : _requestCoach,
                        ),
                        if (_busy) ...[
                          const SizedBox(height: AppSizes.lg),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        const SizedBox(height: AppSizes.xl),
                        Text(context.tr('طلباتي'),
                            style: AppTextStyles.heading3
                                .copyWith(color: AppColors.secondary)),
                        const SizedBox(height: AppSizes.md),
                        if (_items.isEmpty)
                          Text(context.tr('لا توجد طلبات بعد'),
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mutedForeground))
                        else
                          for (final a in _items) ...[
                            _assessmentTile(a),
                            const SizedBox(height: AppSizes.sm),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(context.tr('تقييم متقدم للمستوى'),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              DirectionalIcon(rtl: Icons.chevron_left, ltr: Icons.chevron_right, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assessmentTile(LevelAssessmentItem a) {
    final done = !a.isPending;
    final color = done ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.typeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
                if (a.coachName != null)
                  Text(context.trArgs('المدرب: {p0}', {'p0': a.coachName}), style: AppTextStyles.caption),
                if (done && a.assignedLevelName != null)
                  Text(context.trArgs('النتيجة: {p0} - {p1}', {'p0': a.assignedLevel, 'p1': a.assignedLevelName}),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(done ? context.tr('مكتمل') : context.tr('قيد المراجعة'),
                style: AppTextStyles.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
