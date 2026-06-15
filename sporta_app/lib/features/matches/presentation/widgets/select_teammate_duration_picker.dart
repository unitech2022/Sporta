import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

const Color _gray100 = Color(0xFFF3F4F6);

/// "مدة العرض للموافقة" card with quick-pick hours and a custom input
/// (converted from the duration section in SelectTeammatePage.tsx).
class SelectTeammateDurationPicker extends StatefulWidget {
  const SelectTeammateDurationPicker({
    super.key,
    required this.duration,
    required this.onDurationChanged,
  });

  /// Currently selected duration in hours.
  final int duration;
  final ValueChanged<int> onDurationChanged;

  @override
  State<SelectTeammateDurationPicker> createState() =>
      _SelectTeammateDurationPickerState();
}

class _SelectTeammateDurationPickerState
    extends State<SelectTeammateDurationPicker> {
  static const List<int> _quickOptions = [1, 6, 12, 24, 48];

  bool _showCustomInput = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectQuick(int hours) {
    setState(() {
      _showCustomInput = false;
      _customController.clear();
    });
    widget.onDurationChanged(hours);
  }

  void _onCustomChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 1 && parsed <= 48) {
      widget.onDurationChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'المدة التي يجب على الزميل الموافقة خلالها',
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: AppSizes.iconMd, color: AppColors.primary),
                SizedBox(width: AppSizes.sm),
                Text(
                  'مدة العرض للموافقة',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // الخيارات السريعة
          Row(
            children: [
              for (final hours in _quickOptions) ...[
                if (hours != _quickOptions.first)
                  const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _QuickOption(
                    hours: hours,
                    selected: duration == hours && !_showCustomInput,
                    onTap: () => _selectQuick(hours),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // زر الإدخال المخصص / الإدخال
          if (!_showCustomInput)
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _showCustomInput = true),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '+ مدة مخصصة',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        onChanged: _onCustomChanged,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.secondary),
                        decoration: InputDecoration(
                          hintText: 'أدخل عدد الساعات',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.mutedForeground),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Material(
                      color: _gray100,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showCustomInput = false;
                            _customController.clear();
                          });
                          widget.onDurationChanged(24);
                        },
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: 10,
                          ),
                          child: Icon(
                            Icons.close,
                            size: AppSizes.iconSm,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'من 1 إلى 48 ساعة',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: Text(
              'سيتلقى زميلك إشعاراً ويجب عليه الموافقة خلال $duration ${duration == 1 ? 'ساعة' : 'ساعات'}',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOption extends StatelessWidget {
  const _QuickOption({
    required this.hours,
    required this.selected,
    required this.onTap,
  });

  final int hours;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.onPrimary : AppColors.secondary;

    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: AppSizes.sm,
          ),
          child: Column(
            children: [
              Text(
                '$hours',
                style: AppTextStyles.bodySmall.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hours == 1 ? 'ساعة' : 'س',
                style: AppTextStyles.caption.copyWith(
                  color: foreground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
