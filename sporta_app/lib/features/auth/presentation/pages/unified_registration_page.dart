import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../domain/entities/registration_data.dart';
import '../state/auth_scope.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/role_details_step.dart';
import '../widgets/roles_step.dart';
import '../widgets/summary_step.dart';

/// The ordered stages of the registration flow. [roleDetails] is conditional —
/// it appears only when a coach or venue role is selected.
enum _RegStep { basicInfo, roles, roleDetails, summary }

class UnifiedRegistrationPage extends StatefulWidget {
  const UnifiedRegistrationPage({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  final ValueChanged<RegistrationData> onComplete;
  final VoidCallback onBack;

  @override
  State<UnifiedRegistrationPage> createState() =>
      _UnifiedRegistrationPageState();
}

class _UnifiedRegistrationPageState extends State<UnifiedRegistrationPage> {
  final _data = RegistrationData();
  final _step1FormKey = GlobalKey<FormState>();
  final _step1Key = GlobalKey<BasicInfoStepState>();
  final _roleDetailsFormKey = GlobalKey<FormState>();
  final _roleDetailsKey = GlobalKey<RoleDetailsStepState>();
  int _step = 1;
  String? _apiError;

  /// The active steps for the current role selection (recomputed each build).
  List<_RegStep> get _steps => [
        _RegStep.basicInfo,
        _RegStep.roles,
        if (_data.needsRoleDetails) _RegStep.roleDetails,
        _RegStep.summary,
      ];

  int get _totalSteps => _steps.length;
  _RegStep get _currentStep => _steps[_step - 1];

  Future<void> _next() async {
    switch (_currentStep) {
      case _RegStep.basicInfo:
        final stepState = _step1Key.currentState;
        if (stepState == null || !stepState.validate()) return;
      case _RegStep.roles:
        if (_data.roles.isEmpty) return;
      case _RegStep.roleDetails:
        if (!(_roleDetailsKey.currentState?.validate() ?? false)) return;
      case _RegStep.summary:
        break;
    }

    if (_step < _totalSteps) {
      setState(() {
        _step++;
        _apiError = null;
      });
      return;
    }

    // Final step: call API.
    final auth = context.auth;
    final ok = await auth.register(_data);
    if (!mounted) return;
    if (ok) {
      widget.onComplete(_data);
    } else {
      setState(() => _apiError = auth.errorMessage);
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() {
        _step--;
        _apiError = null;
      });
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;

    return Scaffold(
      body: Column(
        children: [
          _Header(step: _step, totalSteps: _totalSteps, onBack: _back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: switch (_currentStep) {
                _RegStep.basicInfo => BasicInfoStep(
                    key: _step1Key,
                    data: _data,
                    formKey: _step1FormKey,
                  ),
                _RegStep.roles => RolesStep(
                    data: _data,
                    onChanged: () => setState(() {}),
                  ),
                _RegStep.roleDetails => RoleDetailsStep(
                    key: _roleDetailsKey,
                    data: _data,
                    formKey: _roleDetailsFormKey,
                  ),
                _RegStep.summary => SummaryStep(data: _data),
              },
            ),
          ),
          if (_apiError != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding,
              ),
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
                  _apiError!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.destructive),
                ),
              ),
            ),
          _Footer(
            step: _step,
            totalSteps: _totalSteps,
            canProceed:
                _currentStep != _RegStep.roles || _data.roles.isNotEmpty,
            isLoading: auth.isLoading,
            onNext: _next,
            onBack: _back,
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────


class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
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
                context.tr('register'),
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSizes.lg),
              StepProgressBar(currentStep: step, totalSteps: totalSteps),
              const SizedBox(height: AppSizes.sm),
              Text(
                '${context.tr('step')} $step ${context.tr('of')} $totalSteps',
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.totalSteps,
    required this.canProceed,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

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
          child: Row(
            children: [
              if (step > 1) ...[
                TextButton.icon(
                  onPressed: isLoading ? null : onBack,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xxl,
                      vertical: AppSizes.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right,
                      size: AppSizes.iconMd),
                  label: Text(context.tr('back')),
                ),
                const SizedBox(width: AppSizes.md),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: (canProceed && !isLoading) ? onNext : null,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              step == totalSteps
                                  ? context.tr('createAccount')
                                  : context.tr('next'),
                            ),
                            if (step < totalSteps)
                              const Icon(Icons.chevron_left,
                                  size: AppSizes.iconMd),
                          ],
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
