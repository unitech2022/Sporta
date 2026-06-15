import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildContentCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildFooter(),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHeader(VoidCallback onBack) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0EA5D4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xl,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.chevron_right,
                        size: AppSizes.iconMd, color: Colors.white),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'الشروط والأحكام',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.description_outlined,
                size: AppSizes.iconMd, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الشروط والأحكام',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: AppSizes.xs),
                Text('آخر تحديث: 1 يونيو 2026',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContentCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Section(
            title: '١. القبول بالشروط',
            body:
                'باستخدامك تطبيق SPORTA أو تسجيلك فيه، فإنك توافق على الالتزام بهذه الشروط والأحكام وجميع السياسات المرتبطة بها. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٢. استخدام الخدمة',
            body:
                'يُحظر صراحةً القيام بما يلي عند استخدام منصة SPORTA:',
            bullets: [
              'انتهاك أي قوانين أو لوائح محلية أو دولية',
              'نشر محتوى مسيء أو احتيالي أو مضلل',
              'محاولة الوصول غير المصرح به إلى أنظمتنا',
              'إنشاء حسابات متعددة لشخص واحد دون إذن مسبق',
              'استخدام التطبيق لأي غرض تجاري غير مصرح به',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٣. الحسابات والتسجيل',
            body:
                'أنت مسؤول عن الحفاظ على سرية بيانات دخولك وعن جميع الأنشطة التي تتم عبر حسابك. يجب عليك إخطارنا فوراً بأي استخدام غير مصرح به لحسابك. نحتفظ بحق رفض إنشاء الحسابات أو إلغائها وفقاً لتقديرنا.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٤. الحجوزات والدفع',
            body: 'تخضع جميع الحجوزات والمدفوعات للشروط التالية:',
            bullets: [
              'جميع الأسعار بالريال السعودي وتشمل ضريبة القيمة المضافة',
              'يُعدّ الحجز مؤكداً فور اكتمال عملية الدفع بنجاح',
              'تخضع عمليات الاسترجاع لسياسة الاسترجاع الخاصة بنا',
              'نحتفظ بحق تعديل الأسعار مع الإشعار المسبق',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٥. المحتوى والملكية الفكرية',
            body:
                'جميع المحتويات في التطبيق، بما تشمل النصوص والصور والشعارات والرموز والبرمجيات، هي ملكية حصرية لـ SPORTA أو مرخصة لها. يُحظر نسخ أي جزء من هذا المحتوى أو توزيعه أو تعديله دون إذن كتابي مسبق.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٦. المسؤولية',
            body:
                'نسعى دائماً لتقديم خدمة موثوقة وعالية الجودة. ومع ذلك، نخلي مسؤوليتنا عن أي أضرار غير مباشرة أو خسائر عرضية ناتجة عن استخدام التطبيق. حد مسؤوليتنا القصوى لا يتجاوز قيمة آخر معاملة مالية أجريتها عبر التطبيق.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٧. التعديلات على الشروط',
            body:
                'نحتفظ بحق تعديل هذه الشروط في أي وقت. سنخطرك بأي تغييرات جوهرية عبر إشعار داخل التطبيق أو بالبريد الإلكتروني قبل 30 يوماً من سريانها. استمرارك في استخدام الخدمة بعد ذلك يُعدّ قبولاً للشروط المحدّثة.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٨. إنهاء الحساب',
            body:
                'يمكنك إلغاء حسابك في أي وقت من إعدادات التطبيق. نحتفظ بحق تعليق أو إنهاء الحساب في حال انتهاك هذه الشروط أو الاشتباه في أي نشاط احتيالي، مع الإشعار المسبق إلا في حالات الانتهاكات الجسيمة.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٩. القانون الحاكم',
            body:
                'تخضع هذه الشروط لأحكام نظام التجارة الإلكترونية والأنظمة المعمول بها في المملكة العربية السعودية. في حال نشوء أي نزاع، يُختص بالفصل فيه القضاء السعودي وفق الإجراءات القانونية المعتمدة.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '١٠. الاتصال بنا',
            body:
                'لأي استفسار حول هذه الشروط، يمكنك التواصل مع فريقنا القانوني:\n\nالبريد الإلكتروني: legal@sporta.sa',
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          '© 2026 SPORTA. جميع الحقوق محفوظة',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.bullets,
  });

  final String title;
  final String body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            height: 1.6,
          ),
        ),
        if (bullets != null) ...[
          const SizedBox(height: AppSizes.sm),
          for (final b in bullets!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: AppColors.mutedForeground, height: 1.6)),
                  Expanded(
                    child: Text(b,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            height: 1.6)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
