import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/state/app_scope.dart';
import '../state/auth_scope.dart';
import '../../../../core/utils/system_insets.dart';

/// Full-screen white page shown when the account has been suspended by an admin.
/// Offers WhatsApp / call actions to the support number (configured in settings).
class AccountSuspendedPage extends StatefulWidget {
  const AccountSuspendedPage({super.key});

  @override
  State<AccountSuspendedPage> createState() => _AccountSuspendedPageState();
}

class _AccountSuspendedPageState extends State<AccountSuspendedPage> {
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    try {
      final res = await getIt<Dio>().get(ApiEndpoints.supportPhone);
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      if (mounted) setState(() => _phone = data['supportPhone']?.toString());
    } catch (_) {
      // Keep buttons hidden if we can't load the number.
    }
  }

  /// International digits for wa.me (Saudi local 05xxxxxxxx → 9665xxxxxxxx).
  String _waNumber(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0')) d = '966${d.substring(1)}';
    return d;
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('تعذّر فتح التطبيق'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = _phone != null && _phone!.trim().isNotEmpty;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: context.safeBottom(const EdgeInsets.all(AppSizes.xxl)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block,
                        size: 52, color: AppColors.destructive),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    context.tr('تم إيقاف تطبيقك'),
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr(
                        context.tr('الرجاء التواصل مع الدعم الفني لتفعيل الحساب')),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xxxl),
                  if (hasPhone) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _launch(
                            Uri.parse('https://wa.me/${_waNumber(_phone!)}')),
                        icon: const Icon(Icons.chat),
                        label: Text(context.tr('تواصل عبر واتساب')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _launch(Uri.parse('tel:${_phone!.trim()}')),
                        icon: const Icon(Icons.call),
                        label: Text(context.tr('اتصال هاتفي')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    // مكان زرّي التواصل حتى يصل رقم الدعم.
                    const Shimmer(
                      child: Column(
                        children: [
                          SkeletonBox(height: 54, radius: AppSizes.radiusLg),
                          SizedBox(height: AppSizes.md),
                          SkeletonBox(height: 54, radius: AppSizes.radiusLg),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSizes.xl),
                  TextButton(
                    onPressed: () => context.auth.exitSuspended(),
                    child: Text(context.tr('العودة لتسجيل الدخول'),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.mutedForeground)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
