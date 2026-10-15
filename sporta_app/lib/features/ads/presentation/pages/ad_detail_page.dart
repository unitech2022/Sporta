import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/ad_entity.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// Full-screen details for a promo/ad banner tapped from the home slider.
/// Shows the ad image and copy; if the ad's `target` is a known bottom-nav
/// tab, a CTA button jumps there via [onNavigate] after closing this page.
class AdDetailPage extends StatelessWidget {
  const AdDetailPage({super.key, required this.ad, this.onNavigate});

  final AdEntity ad;
  final void Function(String page)? onNavigate;

  static Map<String, String> get _tabLabels => {
    'courts': trg('استكشف الملاعب'),
    'matches': trg('استكشف المباريات'),
    'coaches': trg('استكشف المدربين'),
  };

  bool get _hasTabCta =>
      ad.target != null && _tabLabels.containsKey(ad.target);

  void _openTarget(BuildContext context) {
    final target = ad.target;
    Navigator.of(context).pop();
    if (target != null) onNavigate?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero(context)),
            SliverPadding(
              padding: context
                  .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
              sliver: SliverList.list(children: [
                if (ad.title.isNotEmpty)
                  Text(
                    ad.title,
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.secondary),
                  ),
                if (ad.title.isNotEmpty && ad.subtitle.isNotEmpty)
                  const SizedBox(height: AppSizes.sm),
                if (ad.subtitle.isNotEmpty)
                  Text(
                    ad.subtitle,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.mutedForeground),
                  ),
              ]),
            ),
          ],
        ),
        bottomNavigationBar: _hasTabCta ? _bottomBar(context) : null,
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 11,
          child: Image.network(
            ApiEndpoints.fileUrl(ad.imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
                stops: const [0, 0.45],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: _circleButton(context),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(AppSizes.sm),
          child: DirectionalIcon(
              rtl: Icons.arrow_forward,
              ltr: Icons.arrow_back,
              color: Colors.white,
              size: AppSizes.iconMd),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight + 4,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            onPressed: () => _openTarget(context),
            child: Text(
              context.tr(_tabLabels[ad.target] ?? context.tr('استكشف الآن')),
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
