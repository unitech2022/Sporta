import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';

/// نوع الحدث على ملاعب المالك — كل نوع في تبويب مستقل حتى لا تختلط
/// المباريات بالأمريكانو والبطولات في قائمة واحدة.
enum VenueEventKind {
  match('match'),
  americano('americano'),
  tournament('tournament');

  const VenueEventKind(this.wire);

  /// القيمة المرسلة في وسيط `kind` للـ API.
  final String wire;
}

/// شريط التبويبات الثلاثة أعلى صفحة المباريات (نفس شكل تبويبات اللاعب).
class VenueEventKindTabs extends StatelessWidget {
  const VenueEventKindTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final VenueEventKind selected;
  final ValueChanged<VenueEventKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.sm,
          AppSizes.pagePadding,
          AppSizes.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                icon: Icons.track_changes,
                label: context.tr('مباريات'),
                selected: selected == VenueEventKind.match,
                onTap: () => onChanged(VenueEventKind.match),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _Tab(
                icon: Icons.sync_alt,
                label: context.tr('أمريكانو'),
                selected: selected == VenueEventKind.americano,
                onTap: () => onChanged(VenueEventKind.americano),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _Tab(
                icon: Icons.emoji_events,
                label: context.tr('بطولات'),
                selected: selected == VenueEventKind.tournament,
                onTap: () => onChanged(VenueEventKind.tournament),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.onSecondary;
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: selected ? 4 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.iconMd, color: foreground),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
