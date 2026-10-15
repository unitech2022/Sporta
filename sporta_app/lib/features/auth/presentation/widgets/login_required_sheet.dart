import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../state/auth_scope.dart';

/// بوابة الإجراءات التي تحتاج حساباً في وضع الزائر.
///
/// الزائر يتصفّح الملاعب والمدربين والمباريات بحرية (App Store 5.1.1)، لكن ما
/// يخص حساباً — حجز، انضمام، مفضلة، محفظة — يستدعي تسجيل الدخول. تُنادى في
/// أول سطر من معالج الإجراء:
///
/// ```dart
/// if (await guestBlocked(context)) return;
/// ```
///
/// تعيد `true` حين يكون المستخدم زائراً (فيتوقف الإجراء وقد عُرضت له الدعوة)،
/// و`false` للمستخدم المسجّل فيمضي الإجراء كالمعتاد.
Future<bool> guestBlocked(BuildContext context, {String? message}) async {
  if (!context.auth.isGuest) return false;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _LoginRequiredSheet(message: message),
  );
  return true;
}

class _LoginRequiredSheet extends StatelessWidget {
  const _LoginRequiredSheet({this.message});

  final String? message;

  /// يخرج من وضع الزائر ويعيد تشغيل التطبيق ليُسقط الصفحات المفتوحة، فيبدأ
  /// المستخدم من شاشة الترحيب نظيفاً.
  void _goToAuth(BuildContext context) {
    // تُلتقط المراجع قبل إغلاق الورقة: بعد pop يصبح سياق الورقة معطّلاً.
    final auth = context.auth;
    final settings = context.appSettings;
    Navigator.of(context).pop();
    auth.exitGuest();
    settings.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(AppSizes.md),
          padding: const EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                context.tr('تحتاج حساباً للمتابعة'),
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                message ??
                    context.tr(
                        'التصفّح مفتوح للجميع، أما الحجز والانضمام والمفضلة فتحتاج تسجيل الدخول.'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => _goToAuth(context),
                  child: Text(context.tr('login')),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: OutlinedButton(
                  onPressed: () => _goToAuth(context),
                  child: Text(context.tr('createNewAccount')),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('متابعة التصفّح')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
