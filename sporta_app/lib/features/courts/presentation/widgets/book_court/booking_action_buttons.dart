import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

/// Cancel / confirm action row at the bottom of the booking screen.
class BookingActionButtons extends StatelessWidget {
  const BookingActionButtons({
    super.key,
    required this.canConfirm,
    required this.submitting,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (canConfirm && !submitting) ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('تأكيد الحجز'),
          ),
        ),
      ],
    );
  }
}
