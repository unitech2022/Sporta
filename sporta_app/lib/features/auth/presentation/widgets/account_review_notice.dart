import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/localization/tr_global.dart';

/// نص رسالة «قيد المراجعة» التي تظهر لحساب المدرب/صاحب الملعب فور تسجيله —
/// الحساب لا يُفعَّل إلا بموافقة الأدمن. مصدر واحد للنص تشترك فيه شاشة نهاية
/// التسجيل ونافذة إضافة دور جديد.
String get accountReviewTitle => trg('شكرًا لتسجيلك في سبورتا');

List<String> get accountReviewParagraphs => [
  trg('تم استلام طلب التسجيل بنجاح، وسيقوم فريق سبورتا بمراجعة ملفك والتحقق من البيانات.'),
  trg('سيتم إشعارك بنتيجة المراجعة خلال مدة أقصاها 48 ساعة.'),
  trg('شكرًا لانضمامك إلى مجتمع سبورتا'),
];

/// نافذة تعرض نفس الرسالة — تُستخدم بعد إضافة دور مدرب/ملعب لحساب قائم.
Future<void> showAccountReviewDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      title: Column(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 40, color: AppColors.primary),
          const SizedBox(height: AppSizes.md),
          Text(
            dialogContext.tr(accountReviewTitle),
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final paragraph in accountReviewParagraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Text(
                dialogContext.tr(paragraph),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.tr('حسناً')),
        ),
      ],
    ),
  );
}
