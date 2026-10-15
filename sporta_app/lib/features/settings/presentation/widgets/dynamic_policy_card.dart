import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'policy_markdown.dart';

/// Renders admin-managed policy text (terms/privacy/refund) fetched from
/// `/api/settings/public`, replacing the static fallback content. The text is
/// lightweight Markdown, rendered into organized sections by [PolicyMarkdown].
class DynamicPolicyCard extends StatelessWidget {
  const DynamicPolicyCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: PolicyMarkdown(text: text),
    );
  }
}
