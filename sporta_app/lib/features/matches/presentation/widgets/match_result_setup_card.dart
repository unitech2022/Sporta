import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';

/// "إعداد جدول المباريات" card shared by both Americano variants.
/// The accent colors switch between purple (فرق) and teal (فردي).
class MatchResultSetupCard extends StatelessWidget {
  const MatchResultSetupCard({
    super.key,
    required this.subtitle,
    required this.headerGradient,
    required this.accent,
    required this.accentSoft,
    required this.accentBorder,
    required this.accentLight,
    required this.accentText,
    required this.principles,
    required this.mode,
    required this.onModeChanged,
    required this.timePerRound,
    required this.onTimePerRoundChanged,
    required this.setsCount,
    required this.onSetsCountChanged,
    required this.startTime,
    required this.onStartTimeChanged,
    required this.onGenerate,
  });

  final String subtitle;
  final List<Color> headerGradient;

  /// Strong accent (purple-600 / teal-600).
  final Color accent;

  /// Soft accent for idle icons (purple-500 / teal-500).
  final Color accentSoft;

  /// Card border (purple-200 / teal-200).
  final Color accentBorder;

  /// Tinted background (purple-50 / teal-50).
  final Color accentLight;

  /// Tinted text (purple-700 / teal-700).
  final Color accentText;

  final List<String> principles;
  final MatchResultMode mode;
  final ValueChanged<MatchResultMode> onModeChanged;
  final int timePerRound;
  final ValueChanged<int> onTimePerRoundChanged;
  final int setsCount;
  final ValueChanged<int> onSetsCountChanged;

  /// 'HH:mm'.
  final String startTime;
  final ValueChanged<String> onStartTimeChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: accentBorder, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modeSection(),
                const SizedBox(height: AppSizes.xl),
                if (mode == MatchResultMode.time) _timeSettings(context),
                if (mode == MatchResultMode.sets) _setsSettings(),
                const SizedBox(height: AppSizes.xl),
                _principlesBox(),
                const SizedBox(height: AppSizes.xl),
                _generateButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: headerGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 16, color: Colors.white),
              SizedBox(width: AppSizes.sm),
              Text(
                'إعداد جدول المباريات',
                style:
                    TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: accentBorder, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _modeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: accentSoft),
            const SizedBox(width: 6),
            const Text(
              'نوع الجولة',
              style: TextStyle(
                  fontSize: 12, color: AppColors.secondary, height: 1.4),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _modeButton(
                selected: mode == MatchResultMode.time,
                icon: Icons.timer_outlined,
                title: 'بالوقت',
                subtitle: 'دقائق لكل جولة',
                onTap: () => onModeChanged(MatchResultMode.time),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _modeButton(
                selected: mode == MatchResultMode.sets,
                icon: Icons.tag,
                title: 'بالأشواط',
                subtitle: 'أشواط لكل مباراة',
                onTap: () => onModeChanged(MatchResultMode.sets),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeButton({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? accent : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        side: BorderSide(color: selected ? accent : AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Icon(icon, size: 24, color: selected ? Colors.white : accentSoft),
              const SizedBox(height: AppSizes.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? Colors.white : AppColors.secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      selected ? accentBorder : AppColors.mutedForeground,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مدة الجولة (دقيقة)',
          style:
              TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.4),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            for (final v in const [10, 12, 15, 20]) ...[
              Expanded(
                child: _pillButton(
                  label: '$v',
                  selected: timePerRound == v,
                  onTap: () => onTimePerRoundChanged(v),
                ),
              ),
              if (v != 20) const SizedBox(width: AppSizes.md),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        const Text(
          'وقت البداية',
          style:
              TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.4),
        ),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: () => _pickStartTime(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mrFmtTime(startTime),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.secondary, height: 1.4),
                ),
                Icon(Icons.access_time, size: 18, color: accentSoft),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final parts = startTime.split(':').map(int.parse).toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
    );
    if (picked != null) {
      onStartTimeChanged(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Widget _setsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عدد الأشواط لكل مباراة',
          style:
              TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.4),
        ),
        const SizedBox(height: AppSizes.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final v in const [1, 2, 3, 4, 5, 6]) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: _pillButton(
                    label: '$v',
                    selected: setsCount == v,
                    onTap: () => onSetsCountChanged(v),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: MRColors.gray50,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _stepperButton(
                label: '−',
                filled: false,
                onTap: () =>
                    onSetsCountChanged(setsCount > 1 ? setsCount - 1 : 1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$setsCount',
                      style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.secondary,
                          height: 1.4),
                    ),
                    Text(
                      mrSetsCountLabel(setsCount),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              _stepperButton(
                label: '+',
                filled: true,
                onTap: () =>
                    onSetsCountChanged(setsCount < 20 ? setsCount + 1 : 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? accent : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: filled ? Colors.white : AppColors.secondary,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? accent : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: selected ? accent : AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.white : AppColors.secondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _principlesBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦ مبادئ التوزيع العادل',
            style: TextStyle(fontSize: 12, color: accentText, height: 1.4),
          ),
          const SizedBox(height: AppSizes.sm),
          for (final p in principles)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_outline,
                        size: 12, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                          fontSize: 12, color: accent, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _generateButton() {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: headerGradient,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: InkWell(
          onTap: onGenerate,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 16, color: Colors.white),
                SizedBox(width: AppSizes.sm),
                Text(
                  'توليد جدول المباريات',
                  style: TextStyle(
                      fontSize: 14, color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
