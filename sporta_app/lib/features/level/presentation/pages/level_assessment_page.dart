import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../auth/presentation/widgets/circle_back_button.dart';
import '../cubit/level_cubit.dart';
import 'advanced_assessment_page.dart';
import '../widgets/level_assessment_header.dart';
import '../widgets/level_footer.dart';
import '../widgets/level_option_tile.dart';
import '../widgets/level_result_view.dart';

/// Self-assessment flow shown after registration to determine the player's
/// level. Provides a [LevelCubit] and renders its state; the backend computes
/// and stores the level.
class LevelAssessmentPage extends StatelessWidget {
  const LevelAssessmentPage({
    super.key,
    required this.onComplete,
    required this.onBack,
    this.sport = 'padel',
  });

  /// Called once the level has been computed and saved.
  final VoidCallback onComplete;

  /// Called when the user backs out of the first question.
  final VoidCallback onBack;

  final String sport;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appSettings.language.isRtl;
    return BlocProvider<LevelCubit>(
      create: (_) =>
          getIt<LevelCubit>()..loadQuestions(sport, isArabic: isArabic),
      child: _LevelView(onComplete: onComplete, onBack: onBack, sport: sport),
    );
  }
}

class _LevelView extends StatelessWidget {
  const _LevelView({
    required this.onComplete,
    required this.onBack,
    required this.sport,
  });

  final VoidCallback onComplete;
  final VoidCallback onBack;
  final String sport;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LevelCubit, LevelState>(
      builder: (context, state) {
        if (state.result != null) {
          return LevelResultView(
            result: state.result!,
            onStart: () => _finish(context, state.result!.level),
          );
        }
        if (state.isLoading) return _buildLoading(context);
        if (state.status == LevelStatus.failure || state.questions.isEmpty) {
          return _buildUnavailable(context, state);
        }
        return _buildQuestion(context, state);
      },
    );
  }

  /// الترويسة (بلا شريط الخطوات — عددها غير معروف بعد) وهيكل سؤال وخياراته.
  Widget _buildLoading(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
                    AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleBackButton(onTap: onBack),
                        const SportaLogo(width: 64, white: true),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      context.tr('levelAssessmentTitle'),
                      style:
                          AppTextStyles.heading3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      context.tr('levelAssessmentSubtitle'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Shimmer(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const SkeletonBox(height: 12, width: 80),
                  const SizedBox(height: AppSizes.md),
                  const SkeletonBox(height: 20),
                  const SizedBox(height: AppSizes.sm),
                  const SkeletonBox(height: 20, width: 200),
                  const SizedBox(height: AppSizes.xxl),
                  for (var i = 0; i < 4; i++) ...[
                    const SkeletonBox(height: 56, radius: AppSizes.radiusLg),
                    if (i != 3) const SizedBox(height: AppSizes.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when questions failed to load or none are configured for the sport.
  Widget _buildUnavailable(BuildContext context, LevelState state) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_late_outlined,
                  size: 56, color: AppColors.mutedForeground),
              const SizedBox(height: AppSizes.lg),
              Text(
                state.error ?? context.tr('لا توجد أسئلة تقييم متاحة حالياً'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSizes.xl),
              TextButton(onPressed: onBack, child: Text(context.tr('تخطّي'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, LevelState state) {
    final cubit = context.read<LevelCubit>();
    final lang = context.appSettings.language;
    final question = state.questions[state.index];

    return Scaffold(
      body: Column(
        children: [
          LevelAssessmentHeader(
            step: state.index + 1,
            total: state.questions.length,
            onBack: () => _back(context, state),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('levelQuestionLabel'),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    question.text(lang),
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  for (var i = 0; i < question.options.length; i++) ...[
                    LevelOptionTile(
                      label: question.options[i].label(lang),
                      selected:
                          state.answers[state.index] == question.options[i].score,
                      onTap: () => cubit.selectAnswer(question.options[i].score),
                    ),
                    if (i != question.options.length - 1)
                      const SizedBox(height: AppSizes.md),
                  ],
                  if (kAdvancedAssessmentEnabled && state.atFirstQuestion) ...[
                    const SizedBox(height: AppSizes.lg),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdvancedAssessmentPage(
                              onBack: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.alt_route,
                            color: AppColors.primary),
                        label: Text(context.tr('أو قيّم مستواك بالفيديو أو عبر مدرب'),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (state.error != null) _ErrorBox(message: state.error!),
          LevelFooter(
            isLast: state.isLast,
            canProceed: state.currentAnswered && !state.isSubmitting,
            isLoading: state.isSubmitting,
            onNext: () =>
                cubit.submitOrNext(sport: sport, isArabic: lang.isRtl),
          ),
        ],
      ),
    );
  }

  void _back(BuildContext context, LevelState state) {
    if (state.atFirstQuestion) {
      onBack();
    } else {
      context.read<LevelCubit>().previous();
    }
  }

  Future<void> _finish(BuildContext context, int level) async {
    await context.auth.applyPlayerLevel(level);
    onComplete();
  }
}

/// Inline error banner shown above the footer when submission fails.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
        ),
        child: Text(
          message,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.destructive),
        ),
      ),
    );
  }
}
