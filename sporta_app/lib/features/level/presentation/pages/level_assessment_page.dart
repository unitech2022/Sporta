import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../auth/presentation/widgets/circle_back_button.dart';
import '../../data/level_repository.dart';
import '../../data/padel_questions.dart';

/// Self-assessment flow shown after registration to determine the player's
/// level for the chosen sport. Submits the answers to the backend, which
/// computes and stores the level, then shows the result.
class LevelAssessmentPage extends StatefulWidget {
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
  State<LevelAssessmentPage> createState() => _LevelAssessmentPageState();
}

class _LevelAssessmentPageState extends State<LevelAssessmentPage> {
  final _repo = LevelRepository();
  final _questions = padelQuestions;

  int _index = 0;
  late final List<int?> _answers = List<int?>.filled(_questions.length, null);
  bool _submitting = false;
  String? _error;
  LevelAssessmentResult? _result;

  void _select(int score) {
    setState(() => _answers[_index] = score);
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _error = null;
      });
    } else {
      _submit();
    }
  }

  void _back() {
    if (_index > 0) {
      setState(() {
        _index--;
        _error = null;
      });
    } else {
      widget.onBack();
    }
  }

  Future<void> _submit() async {
    // Capture context-derived values before the await.
    final isAr = context.appSettings.language.isRtl;
    final unexpected = context.tr('unexpectedError');

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _repo.submitAssessment(
        sport: widget.sport,
        answers: _answers.cast<int>(),
      );
      if (!mounted) return;
      // Show the result first; the cached user level is applied on "start" so
      // the result screen isn't swapped out by the app entry gate.
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.localized(isAr));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = unexpected);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _finish() async {
    final auth = context.auth;
    await auth.applyPlayerLevel(_result!.level);
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(result: _result!, onStart: _finish);
    }

    final lang = context.appSettings.language;
    final question = _questions[_index];
    final answered = _answers[_index] != null;

    return Scaffold(
      body: Column(
        children: [
          _Header(step: _index + 1, total: _questions.length, onBack: _back),
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
                    _OptionTile(
                      label: question.options[i].label(lang),
                      selected: _answers[_index] == question.options[i].score,
                      onTap: () => _select(question.options[i].score),
                    ),
                    if (i != question.options.length - 1)
                      const SizedBox(height: AppSizes.md),
                  ],
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.destructive.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.destructive),
                ),
              ),
            ),
          _Footer(
            isLast: _index == _questions.length - 1,
            canProceed: answered && !_submitting,
            isLoading: _submitting,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.total, required this.onBack});

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
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
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                context.tr('levelAssessmentSubtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: AppSizes.lg),
              StepProgressBar(currentStep: step, totalSteps: total),
              const SizedBox(height: AppSizes.sm),
              Text(
                '${context.tr('step')} $step ${context.tr('of')} $total',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.lg,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: AppSizes.iconMd,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: selected ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isLast,
    required this.canProceed,
    required this.isLoading,
    required this.onNext,
  });

  final bool isLast;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? onNext : null,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast
                          ? context.tr('calculateMyLevel')
                          : context.tr('next'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onStart});

  final LevelAssessmentResult result;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final lang = context.appSettings.language;
    final name = lang.isRtl ? result.levelNameAr : result.levelNameEn;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${result.level}',
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                context.tr('yourLevelIs'),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                name,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.secondary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                context.tr('levelResultHint'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.xxxl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: Text(context.tr('startNow')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
