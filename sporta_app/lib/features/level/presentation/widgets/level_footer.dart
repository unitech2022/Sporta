import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/state/app_scope.dart';

/// Bottom action bar with the "next" / "calculate level" button.
class LevelFooter extends StatelessWidget {
  const LevelFooter({
    super.key,
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
