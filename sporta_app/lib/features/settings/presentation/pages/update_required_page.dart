import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';

/// Full-screen forced-update gate, shown when the admin raises
/// `version_android` / `version_ios` in system settings above the installed
/// version. Not dismissible — like [MaintenancePage] it replaces the app entry
/// until the user updates and relaunches.
///
/// The update button first tries the Google Play in-app immediate update (no
/// store visit needed); if Play can't serve it (iOS, sideload, emulator) it
/// falls back to opening the store listing.
class UpdateRequiredPage extends StatefulWidget {
  const UpdateRequiredPage({super.key});

  static const String _playUrl =
      'https://play.google.com/store/apps/details?id=com.sportaapp.sporta_app';

  // TODO: replace with the real App Store id once the iOS app is published.
  static const String _appStoreUrl = 'https://apps.apple.com/app/id0000000000';

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage> {
  bool _busy = false;

  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await InAppUpdate.performImmediateUpdate();
          return; // Play takes over; the app restarts on the new version.
        } catch (_) {
          // Play unavailable — fall through to the store listing.
        }
      }
      final url = !kIsWeb && Platform.isIOS
          ? UpdateRequiredPage._appStoreUrl
          : UpdateRequiredPage._playUrl;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    context.tr('تحديث جديد متوفر'),
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr(
                      context.tr(
                        'هذا الإصدار لم يعد مدعومًا. حدّث التطبيق للاستمرار في استخدام سبورتا.',
                      ),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _update,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(context.tr('تحديث الآن')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.lg,
                        ),
                      ),
                    ),
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
