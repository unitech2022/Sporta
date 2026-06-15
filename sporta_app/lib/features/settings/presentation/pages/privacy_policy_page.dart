import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key, required this.onBack});
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
                  'سياسة الخصوصية',
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
            child: const Icon(Icons.shield_outlined,
                size: AppSizes.iconMd, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نحن نحترم خصوصيتك',
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
            title: '١. المقدمة',
            body:
                'في SPORTA، نلتزم بحماية خصوصيتك وضمان أمان بياناتك الشخصية. تصف هذه السياسة كيفية جمع واستخدام ومشاركة معلوماتك عند استخدام تطبيقنا وخدماتنا. باستخدامك لتطبيق SPORTA، فإنك توافق على الشروط الواردة في هذه السياسة.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٢. المعلومات التي نجمعها',
            body: 'نجمع أنواعاً مختلفة من المعلومات لتقديم خدماتنا وتحسينها:',
            bullets: [
              'معلومات الحساب: الاسم، رقم الجوال، البريد الإلكتروني، كلمة المرور المشفرة',
              'الملف الشخصي: الصورة الشخصية، المستوى الرياضي، الرياضات المفضلة',
              'معلومات الحجز: تفاصيل الملاعب، التواريخ، مواعيد الجلسات',
              'بيانات الموقع: موقعك لعرض الملاعب والمدربين القريبين منك',
              'بيانات الاستخدام: كيفية تفاعلك مع التطبيق، الصفحات التي تزورها',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٣. كيف نستخدم معلوماتك',
            body: 'نستخدم المعلومات المجمعة للأغراض التالية:',
            bullets: [
              'تشغيل وتحسين خدمات التطبيق',
              'معالجة الحجوزات والمدفوعات',
              'التواصل معك بشأن حجوزاتك وتحديثات الحساب',
              'تخصيص تجربتك وتقديم توصيات مناسبة',
              'حل النزاعات وتطبيق سياساتنا',
              'تحليل الاستخدام لتطوير ميزات جديدة',
              'الامتثال للمتطلبات القانونية',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٤. مشاركة المعلومات',
            body:
                'لا نبيع معلوماتك الشخصية. قد نشاركها في الحالات التالية فقط:',
            bullets: [
              'مع أصحاب الملاعب والمدربين لتنفيذ الحجوزات',
              'مع مزودي خدمات الدفع لمعالجة المعاملات المالية',
              'مع شركاء الخدمة الموثوقين الملتزمين بسياساتنا',
              'عند الضرورة القانونية أو بناءً على أوامر قضائية',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٥. أمان المعلومات',
            body:
                'نطبق معايير أمنية صارمة لحماية بياناتك، بما في ذلك التشفير أثناء النقل والتخزين، والتحكم في الوصول. ومع ذلك، لا يوجد نظام آمن بالكامل، لذا ننصحك باستخدام كلمة مرور قوية وفريدة لحسابك.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٦. حقوقك',
            body: 'لديك الحق في:',
            bullets: [
              'الوصول إلى بياناتك الشخصية وطلب نسخة منها',
              'تصحيح أي معلومات غير دقيقة',
              'طلب حذف بياناتك (مع مراعاة الالتزامات القانونية)',
              'الاعتراض على معالجة بياناتك لأغراض معينة',
              'سحب الموافقة في أي وقت',
              'تقديم شكوى إلى الجهات الرقابية المختصة',
            ],
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٧. ملفات تعريف الارتباط',
            body:
                'نستخدم ملفات تعريف الارتباط والتقنيات المشابهة لتحسين أداء التطبيق وتخصيص التجربة. يمكنك التحكم في هذه الملفات من خلال إعدادات جهازك، مع العلم أن ذلك قد يؤثر على بعض وظائف التطبيق.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٨. خصوصية الأطفال',
            body:
                'لا يستهدف تطبيقنا الأشخاص دون سن 13 عاماً ولا نجمع معلوماتهم عن قصد. إذا اكتشفنا جمع بيانات طفل دون إذن ولي الأمر، سنحذفها فوراً. إذا كنت ولي أمر وتعتقد أن طفلك زودنا ببياناته، يرجى التواصل معنا.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '٩. الاحتفاظ بالبيانات',
            body:
                'نحتفظ ببياناتك طالما كان حسابك نشطاً أو عند الحاجة لتقديم الخدمات. عند إغلاق الحساب، نحذف بياناتك خلال 90 يوماً، مع الاحتفاظ ببعض المعلومات لمدة تصل إلى 7 سنوات للامتثال للمتطلبات القانونية والضريبية.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '١٠. التعديلات على السياسة',
            body:
                'قد نحدث هذه السياسة من وقت لآخر. سنخطرك بأي تغييرات جوهرية عبر إشعار في التطبيق أو بالبريد الإلكتروني قبل 30 يوماً من سريان التعديلات. استمرارك في استخدام التطبيق بعد ذلك يُعدّ موافقةً على السياسة المحدّثة.',
          ),
          SizedBox(height: AppSizes.xl),
          _Section(
            title: '١١. الاتصال بنا',
            body:
                'إذا كان لديك أي استفسار حول سياسة الخصوصية، يمكنك التواصل معنا:\n\nالبريد الإلكتروني: privacy@sporta.sa\nالهاتف: +966 50 123 4567',
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
