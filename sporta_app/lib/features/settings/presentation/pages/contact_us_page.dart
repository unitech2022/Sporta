import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  String _subject = '';
  String _message = '';
  bool _emailSent = false;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _sendEmail() {
    if (_subject.isEmpty || _message.isEmpty) return;
    setState(() => _emailSent = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _emailSent = false;
          _subject = '';
          _message = '';
          _subjectCtrl.clear();
          _messageCtrl.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildWhatsAppCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildEmailCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildLiveChatCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildWorkingHoursCard(),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  onTap: widget.onBack,
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
                  'اتصل بنا',
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

  Widget _buildInfoCard() {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.support_agent,
                size: AppSizes.iconSm, color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(
            child: Text(
              'نحن هنا لمساعدتك! اختر طريقة التواصل المفضلة',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سيتم فتح واتساب')),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Icon(Icons.message_outlined,
                  color: Colors.white, size: AppSizes.iconMd),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('واتساب',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600)),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '+966 56 188 3558',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left,
                size: AppSizes.iconMd, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: const Icon(Icons.email_outlined,
                      color: Colors.white, size: AppSizes.iconMd),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البريد الإلكتروني',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                      Text('support@sporta.sa',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.lg),
            if (_emailSent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF16A34A), size: AppSizes.iconMd),
                    SizedBox(width: AppSizes.sm),
                    Text('تم إرسال رسالتك بنجاح!',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _subjectCtrl,
                onChanged: (v) => setState(() => _subject = v),
                decoration: InputDecoration(
                  labelText: 'الموضوع',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _messageCtrl,
                onChanged: (v) => setState(() => _message = v),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'الرسالة',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: (_subject.isNotEmpty && _message.isNotEmpty)
                      ? _sendEmail
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_subject.isNotEmpty &&
                            _message.isNotEmpty)
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE5E7EB),
                    foregroundColor: (_subject.isNotEmpty &&
                            _message.isNotEmpty)
                        ? Colors.white
                        : AppColors.mutedForeground,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send, size: AppSizes.iconSm),
                      SizedBox(width: AppSizes.sm),
                      Text('إرسال الرسالة'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChatCard() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سيتم فتح الدردشة المباشرة')),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0EA5D4)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: AppSizes.iconMd),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الدردشة المباشرة',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600)),
                  Text('تحدث مع فريق الدعم مباشرة',
                      style: AppTextStyles.caption),
                  SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSizes.xs),
                      Text('متصل الآن',
                          style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left,
                size: AppSizes.iconMd, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: AppSizes.iconSm, color: AppColors.mutedForeground),
              SizedBox(width: AppSizes.sm),
              Text('أوقات العمل',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _hoursRow('السبت - الخميس:', '9:00 صباحاً - 6:00 مساءً'),
          SizedBox(height: AppSizes.sm),
          _hoursRow('الجمعة:', 'مغلق'),
        ],
      ),
    );
  }

  Widget _hoursRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground)),
        Text(hours,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
