import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../widgets/matches_americano_tab.dart';
import '../widgets/matches_open_matches_tab.dart';

/// المباريات — converted from MatchesPage.tsx.
class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key, this.onBack, this.onNavigate});

  final VoidCallback? onBack;

  /// Navigation callback. Page ids: 'create-match', 'join-match',
  /// 'create-americano', 'join-americano', 'match-result'.
  final void Function(String page, [String? matchType])? onNavigate;

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

enum _MatchesTab { matches, americano }

class _MatchesPageState extends State<MatchesPage> {
  _MatchesTab _activeTab = _MatchesTab.matches;

  bool get _isMatchesTab => _activeTab == _MatchesTab.matches;

  void _navigate(String page, [String? matchType]) =>
      widget.onNavigate?.call(page, matchType);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                      vertical: AppSizes.lg,
                    ),
                    child: Column(
                      children: [
                        _buildFilterChips(),
                        const SizedBox(height: AppSizes.xl),
                        if (_isMatchesTab)
                          MatchesOpenMatchesTab(onNavigate: _navigate)
                        else
                          MatchesAmericanoTab(onNavigate: _navigate),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      0,
                      AppSizes.pagePadding,
                      AppSizes.pagePadding,
                    ),
                    child: _buildCreateButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GradientPageHeader(
      title: 'المباريات',
      onBack: widget.onBack,
      trailing: [
        _HeaderCreateButton(
          label: _isMatchesTab ? 'إنشاء مباراة' : 'إنشاء أمريكانو',
          onTap: () =>
              _navigate(_isMatchesTab ? 'create-match' : 'create-americano'),
        ),
      ],
      bottom: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HeaderTabButton(
                  icon: Icons.track_changes,
                  label: 'مباريات مفتوحة',
                  selected: _isMatchesTab,
                  onTap: () =>
                      setState(() => _activeTab = _MatchesTab.matches),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _HeaderTabButton(
                  icon: Icons.emoji_events,
                  label: 'أمريكانو',
                  selected: !_isMatchesTab,
                  onTap: () =>
                      setState(() => _activeTab = _MatchesTab.americano),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          AppSearchField(
            hint: _isMatchesTab ? 'ابحث عن مباراة...' : 'ابحث عن أمريكانو...',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _FilterPill(label: 'الكل', selected: true),
          SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'فلترة حسب المستوى',
            child: _FilterPill(label: 'المستوى', icon: Icons.tune),
          ),
          SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'فلترة حسب التاريخ',
            child: _FilterPill(label: 'التاريخ'),
          ),
          SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'فلترة حسب الموقع القريب',
            child: _FilterPill(label: 'الموقع'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: () =>
              _navigate(_isMatchesTab ? 'create-match' : 'create-americano'),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isMatchesTab ? Icons.group : Icons.emoji_events,
                  size: AppSizes.iconMd,
                  color: AppColors.onPrimary,
                ),
                SizedBox(width: AppSizes.sm),
                Text(
                  _isMatchesTab ? 'أنشئ مباراة جديدة' : 'أنشئ أمريكانو جديد',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact create button shown in the header next to the title.
class _HeaderCreateButton extends StatelessWidget {
  const _HeaderCreateButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: AppSizes.iconMd,
                color: AppColors.onPrimary,
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header tab (مباريات مفتوحة / أمريكانو).
class _HeaderTabButton extends StatelessWidget {
  const _HeaderTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

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
              SizedBox(width: AppSizes.sm),
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

/// Round filter chip below the header (الكل / المستوى / التاريخ / الموقع).
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.selected = false, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
                SizedBox(width: AppSizes.xs),
              ],
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
