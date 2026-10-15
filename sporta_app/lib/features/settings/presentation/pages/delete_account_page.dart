import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/otp_models.dart';
import '../../../auth/presentation/pages/otp_page.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../../core/utils/system_insets.dart';

/// حذف الحساب نهائياً — متطلب App Store 5.1.1(v): مسار كامل داخل التطبيق بلا
/// إحالة إلى الدعم. الخطوات: شرح ما سيُحذف ← إقرار ← تأكيد أخير ← رمز واتساب.
///
/// كان التأكيد بكلمة المرور، وصار برمز يصل إلى جهاز صاحب الحساب لحظتها — بعد
/// أن زالت كلمات السر من التطبيق، وهو تأكيد أقوى لا أضعف.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  bool _acknowledged = false;
  bool _deleting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    if (_deleting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('يرجى الإقرار بأن الحذف نهائي قبل المتابعة'),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('تأكيد حذف الحساب')),
        content: Text(
          ctx.tr(
            'سيتم حذف حسابك وبياناتك نهائياً ولا يمكن التراجع. هل تريد المتابعة؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(ctx.tr('نعم، احذف حسابي')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // الرمز يُطلب بعد التأكيد لا قبله: لا رسالة تُرسل لمن تراجع عند آخر خطوة.
    final token = await _confirmByOtp();
    if (token == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final auth = context.auth;
    setState(() => _deleting = true);
    final error = await auth.deleteAccount(token, reason: _reason.text);
    if (!mounted) return;
    setState(() => _deleting = false);

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // نجح الحذف: الجلسة انتهت أصلاً داخل الكيوبت. تأكيد صريح يراه المستخدم
    // (والمراجع في تسجيل الشاشة)، ثم إعادة تشغيل التطبيق تُسقط كل الصفحات
    // المفتوحة فيعود إلى شاشة الترحيب من جديد.
    final settings = context.appSettings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF16A34A),
          size: 40,
        ),
        title: Text(ctx.tr('تم حذف الحساب')),
        content: Text(trg('تم حذف حسابك نهائياً. نأسف لمغادرتك.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('حسناً')),
          ),
        ],
      ),
    );
    settings.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: context.safeBottom(
                  const EdgeInsets.all(AppSizes.pagePadding),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _warningCard(),
                      const SizedBox(height: AppSizes.lg),
                      _whatGetsDeletedCard(),
                      const SizedBox(height: AppSizes.lg),
                      _acknowledgeTile(),
                      const SizedBox(height: AppSizes.lg),
                      _otpNotice(),
                      const SizedBox(height: AppSizes.lg),
                      _reasonField(),
                      const SizedBox(height: AppSizes.xxl),
                      _deleteButton(),
                      const SizedBox(height: AppSizes.md),
                      TextButton(
                        onPressed: _deleting ? null : widget.onBack,
                        child: Text(context.tr('الاحتفاظ بحسابي')),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
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
                  onTap: _deleting ? null : widget.onBack,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: DirectionalIcon(
                      rtl: Icons.chevron_right,
                      ltr: Icons.chevron_left,
                      size: AppSizes.iconMd,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.tr('حذف الحساب'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr(
                'حذف الحساب إجراء نهائي لا يمكن التراجع عنه. لن تتمكن من تسجيل الدخول مرة أخرى، ولن نتمكن من استعادة بياناتك بعد الحذف.',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF991B1B),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whatGetsDeletedCard() {
    final items = <String>[
      context.tr('بياناتك الشخصية: الاسم والجوال وصورة الملف والوثائق'),
      context.tr('بيانات حسابك البنكي وموقعك المحفوظ ونقاط الولاء'),
      context.tr('إشعاراتك وأصدقاؤك وملاعبك المفضلة ومحادثات الدعم'),
      context.tr('حجوزاتك وجلساتك التدريبية القادمة (تُلغى)'),
      context.tr('رصيد محفظتك المتبقي — اسحبه قبل الحذف'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ماذا سيُحذف؟'),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.close_rounded,
                      size: AppSizes.iconSm,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: AppSizes.xl),
          Text(
            context.tr(
              'تبقى السجلات المالية السابقة (الحجوزات وعمليات الدفع) محفوظة بصيغة لا ترتبط بهويتك، للأغراض المحاسبية والنظامية فقط.',
            ),
            style: AppTextStyles.caption.copyWith(height: 1.6),
          ),
          if (context.auth.user?.roles.contains(UserRole.venue) == true) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              context.tr(
                'بصفتك ملعباً: ستُزال ملاعبك من التطبيق، وتُلغى حجوزات اللاعبين القادمة فيها مع ردّ مبالغها إلى محافظهم.',
              ),
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF92400E),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _acknowledgeTile() {
    return InkWell(
      onTap: () => setState(() => _acknowledged = !_acknowledged),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acknowledged,
              activeColor: const Color(0xFFDC2626),
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.tr('أفهم أن حذف حسابي نهائي ولا يمكن التراجع عنه'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// يرسل رمز تأكيد ويفتح شاشة إدخاله. يُرجِع التذكرة أو `null` إن تراجع
  /// المستخدم أو فشل الإرسال.
  Future<String?> _confirmByOtp() async {
    final auth = context.auth;
    final phone = auth.user?.phone ?? '';
    final messenger = ScaffoldMessenger.of(context);

    final sent = await auth.requestOtp(phone, OtpPurpose.deleteAccount);
    if (!mounted) return null;
    if (sent == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? trg('تعذّر إرسال رمز التأكيد')),
        ),
      );
      return null;
    }

    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: phone,
          purpose: OtpPurpose.deleteAccount,
          initial: sent,
          onVerified: (token) => Navigator.of(context).pop(token),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// يشرح خطوة التأكيد قبل الضغط، فلا يفاجئه رمزٌ لم يطلبه.
  Widget _otpNotice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.chat_bubble_outline,
          size: AppSizes.iconSm,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            context.tr('سنرسل رمز تأكيد قبل إتمام الحذف'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('سبب الحذف (اختياري)'),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: _reason,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: context.tr('ساعدنا على التحسّن — ما سبب مغادرتك؟'),
          ),
        ),
      ],
    );
  }

  Widget _deleteButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _deleting ? null : _confirmAndDelete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
        ),
        child: _deleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(context.tr('حذف حسابي نهائياً')),
      ),
    );
  }
}
