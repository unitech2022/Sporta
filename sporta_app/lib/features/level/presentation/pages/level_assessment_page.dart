import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../data/padel_questions.dart';
import '../cubit/level_cubit.dart';
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
    return BlocProvider<LevelCubit>(
      create: (_) => getIt<LevelCubit>()..init(padelQuestions.length),
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
        return _buildQuestion(context, state);
      },
    );
  }

  Widget _buildQuestion(BuildContext context, LevelState state) {
    final cubit = context.read<LevelCubit>();
    final lang = context.appSettings.language;
    final question = padelQuestions[state.index];

    return Scaffold(
      body: Column(
        children: [
          LevelAssessmentHeader(
            step: state.index + 1,
            total: padelQuestions.length,
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
