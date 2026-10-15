import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/support_message.dart';
import '../../../../core/localization/app_dates.dart';

/// فقاعة رسالة واحدة: رسائلي على جهة البداية بلون العلامة، وردود الدعم
/// على الجهة المقابلة ببطاقة بيضاء.
class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({super.key, required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: mine
                    ? null
                    : Border.all(color: AppColors.divider, width: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        // اللاعب يخاطب «الدعم الفني» لا موظفاً بعينه، فيُخفى
                        // اسم المرسل الحقيقي خلف اسم الجهة.
                        context.tr('الدعم الفني'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    message.body,
                    style: AppTextStyles.body.copyWith(
                      color: mine ? AppColors.onPrimary : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _time(message.sentAt),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: mine
                              ? AppColors.onPrimary.withValues(alpha: 0.75)
                              : AppColors.mutedForeground,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readAt != null ? Icons.done_all : Icons.done,
                          size: 12,
                          color: AppColors.onPrimary.withValues(alpha: 0.75),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أوقات المحادثة مخزّنة على ساعة التطبيق (UTC+3) وتُعرض كما هي.
  static String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${AppDates.periodShort(d)}';
  }
}
