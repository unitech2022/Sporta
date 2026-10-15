import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../widgets/leaderboard_board.dart';
import '../../../../core/utils/system_insets.dart';

/// «عرض الكل» لقسم نقاط المستوى والمكافآت: أعلى 50 لاعباً.
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
                      AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const DirectionalIcon(
                            rtl: Icons.arrow_forward,
                            ltr: Icons.arrow_back,
                            color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Text(context.tr('نقاط المستوى والمكافآت'),
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: context.safeBottom(
                    const EdgeInsets.all(AppSizes.pagePadding)),
                child: const LeaderboardBoard(limit: 50, compact: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
