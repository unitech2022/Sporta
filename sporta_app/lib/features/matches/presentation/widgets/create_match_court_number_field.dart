import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import 'create_match_choice_button.dart';
import 'create_match_field_label.dart';

/// اختيار الملعب الداخلي (1..عدد الملاعب) داخل النادي المختار — نفس فكرة
/// منتقي رقم الملعب في حجز الملعب، بمظهر حقول نموذج إنشاء المباراة.
class CreateMatchCourtNumberField extends StatelessWidget {
  const CreateMatchCourtNumberField({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelect,
  });

  final String label;

  /// عدد الملاعب الداخلية التي أضافها المالك (1 على الأقل).
  final int count;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = count < 1 ? 1 : count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(text: label, icon: Icons.grid_view_outlined),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.md,
          children: [
            for (var number = 1; number <= total; number++)
              SizedBox(
                width: 56,
                child: CreateMatchChoiceButton(
                  label: '$number',
                  selected: selected == number,
                  onTap: () => onSelect(number),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
