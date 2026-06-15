import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key, required this.onBack});
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
                  'سياسة الاسترجاع',
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
            child: const Icon(Icons.attach_money,
                size: AppSizes.iconMd, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سياسة واضحة وعادلة للاسترجاع',
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
        children: [
          const _TextSection(
            title: '١. نظرة عامة',
            body:
                'تلتزم SPORTA بتقديم سياسة استرجاع شفافة وعادلة لجميع المستخدمين. نفهم أن الظروف قد تتغير، لذا وضعنا هذه السياسة لضمان حقوقك وحماية مصالح جميع الأطراف.',
          ),
          const SizedBox(height: AppSizes.xl),
          const _SectionTitle(title: '٢. حجوزات الملاعب'),
          const SizedBox(height: AppSizes.md),
          _refundCard(
            bg: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFF16A34A),
            textColor: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            title: 'الإلغاء قبل 24 ساعة أو أكثر',
            subtitle: 'استرجاع كامل المبلغ (100%)',
          ),
          const SizedBox(height: AppSizes.md),
          _refundCard(
            bg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFD97706),
            textColor: const Color(0xFFD97706),
            icon: Icons.access_time,
            title: 'الإلغاء قبل 12-24 ساعة',
            subtitle: 'استرجاع 50% من المبلغ',
          ),
          const SizedBox(height: AppSizes.md),
          _refundCard(
            bg: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFDC2626),
            textColor: const Color(0xFFDC2626),
            icon: Icons.cancel_outlined,
            title: 'الإلغاء قبل أقل من 12 ساعة أو عدم الحضور',
            subtitle: 'لا يوجد استرجاع (0%)',
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٣. حصص التدريب',
            bullets: [
              'الإلغاء قبل 24 ساعة: استرجاع كامل',
              'الإلغاء قبل 12-24 ساعة: استرجاع 50%',
              'الإلغاء المتأخر أو الغياب: لا يوجد استرجاع',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٤. البطولات والفعاليات',
            bullets: [
              'الانسحاب قبل 7 أيام: استرجاع كامل',
              'الانسحاب قبل 3-7 أيام: استرجاع 50%',
              'الانسحاب قبل أقل من 3 أيام: لا يوجد استرجاع',
              'في حال إلغاء الفعالية من قِبل المنظم: استرجاع كامل',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٥. الحالات الاستثنائية',
            body: 'يُمنح استرجاع كامل بصرف النظر عن توقيت الإلغاء في الحالات التالية:',
            bullets: [
              'الإصابة الرياضية الموثقة طبياً',
              'وفاة أحد أفراد الأسرة المباشرة',
              'قرارات حكومية أو ظروف قاهرة',
              'إلغاء الخدمة من جانب مزود الملعب أو المدرب',
              'أعطال تقنية جسيمة في منصة التطبيق',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٦. طريقة الاسترجاع',
            bullets: [
              'يُعاد المبلغ إلى نفس وسيلة الدفع الأصلية',
              'الاسترجاع إلى البطاقة الائتمانية: 5-10 أيام عمل',
              'الاسترجاع إلى المحفظة الرقمية: خلال 24 ساعة',
              'لا تُفرض أي رسوم إضافية على عمليات الاسترجاع',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٧. كيفية طلب الاسترجاع',
            numberedSteps: [
              'افتح التطبيق وانتقل إلى "حجوزاتي"',
              'اختر الحجز المراد إلغاؤه',
              'اضغط على "إلغاء الحجز"',
              'حدد سبب الإلغاء من القائمة',
              'أكّد طلب الإلغاء',
              'ستصلك رسالة تأكيد مع تفاصيل المبلغ المُسترجع',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٨. المبالغ غير القابلة للاسترجاع',
            bullets: [
              'رسوم الخدمة ومعالجة الدفع',
              'المبالغ المستخدمة كنقاط مكافآت',
              'رسوم الاشتراكات المستهلكة جزئياً',
              'الحجوزات التي تجاوزت مواعيد الإلغاء المحددة',
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '٩. النزاعات',
            body:
                'في حال وجود أي خلاف حول عملية استرجاع، يمكنك التواصل مع فريق الدعم خلال 14 يوماً من تاريخ الحجز. سنراجع حالتك بعناية وسنردّ عليك خلال 3 أيام عمل.',
          ),
          const SizedBox(height: AppSizes.xl),
          const _TextSection(
            title: '١٠. الاتصال بنا',
            body:
                'للاستفسار عن طلبات الاسترجاع، يمكن التواصل معنا عبر:\n\nالبريد الإلكتروني: refunds@sporta.sa\nالهاتف: +966 50 123 4567\nأوقات العمل: السبت - الخميس، 9:00 صباحاً - 6:00 مساءً',
          ),
        ],
      ),
    );
  }

  static Widget _refundCard({
    required Color bg,
    required Color borderColor,
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: textColor),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.4)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.8),
                        height: 1.4)),
              ],
            ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.secondary,
        height: 1.5,
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.title,
    this.body,
    this.bullets,
    this.numberedSteps,
  });

  final String title;
  final String? body;
  final List<String>? bullets;
  final List<String>? numberedSteps;

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
        if (body != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text(body!,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 1.6)),
        ],
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
        if (numberedSteps != null) ...[
          const SizedBox(height: AppSizes.sm),
          for (var i = 0; i < numberedSteps!.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                          height: 1.6,
                          fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(numberedSteps![i],
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
