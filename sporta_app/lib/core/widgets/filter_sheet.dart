import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';
import '../../core/utils/system_insets.dart';

/// Draws the filter controls for the sheet's current [draft]. Every control
/// reports the whole updated value through [onChanged]; nothing is applied to
/// the screen until "تطبيق" is pressed.
typedef FilterSheetBuilder<T> =
    Widget Function(BuildContext context, T draft, ValueChanged<T> onChanged);

/// The one filter bottom sheet the whole app uses: a title with a close icon,
/// the screen's own filter sections, and an apply button.
///
/// Resolves to the value to apply, or null when the sheet is dismissed (close
/// icon, back, or tapping outside) — in that case the screen keeps its filters.
Future<T?> showFilterSheet<T>({
  required BuildContext context,
  required T initialValue,
  required FilterSheetBuilder<T> builder,
  String title = 'الفلاتر',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (_) => _FilterSheet<T>(
      initialValue: initialValue,
      builder: builder,
      title: title,
    ),
  );
}

class _FilterSheet<T> extends StatefulWidget {
  const _FilterSheet({
    required this.initialValue,
    required this.builder,
    required this.title,
  });

  final T initialValue;
  final FilterSheetBuilder<T> builder;
  final String title;

  @override
  State<_FilterSheet<T>> createState() => _FilterSheetState<T>();
}

class _FilterSheetState<T> extends State<_FilterSheet<T>> {
  late T _draft = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.sm,
                AppSizes.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr(widget.title),
                      style: AppTextStyles.heading2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.mutedForeground,
                    tooltip: context.tr('إلغاء'),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: AppSizes.lg),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                  vertical: AppSizes.sm,
                ),
                child: widget.builder(
                  context,
                  _draft,
                  (value) => setState(() => _draft = value),
                ),
              ),
            ),
            Padding(
              padding: context.safeBottom(const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.lg,
                AppSizes.pagePadding,
                AppSizes.lg,
              )),
              child: AppButton(
                label: context.tr('تطبيق'),
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
