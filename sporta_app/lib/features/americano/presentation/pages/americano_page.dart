import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/gradient_page_header.dart';

const _kGreen50 = Color(0xFFF0FDF4);
const _kGreen500 = Color(0xFF22C55E);
const _kGreen600 = Color(0xFF16A34A);
const _kRed50 = Color(0xFFFEF2F2);
const _kRed600 = Color(0xFFDC2626);
const _kBlue50 = Color(0xFFEFF6FF);
const _kBlue600 = Color(0xFF2563EB);
const _kPurple50 = Color(0xFFF5F3FF);
const _kPurple600 = Color(0xFF7C3AED);
const _kGray50 = Color(0xFFF9FAFB);
const _kGray100 = Color(0xFFF3F4F6);
const _kGray200 = Color(0xFFE5E7EB);

class _AmericanoEvent {
  const _AmericanoEvent({
    required this.id,
    required this.type,
    required this.courtName,
    required this.location,
    required this.distance,
    required this.date,
    required this.time,
    required this.duration,
    required this.minLevel,
    required this.maxLevel,
    required this.currentPlayers,
    required this.totalPlayers,
    required this.costPerPlayer,
    required this.gender,
    required this.rounds,
  });

  final String id;
  final String type;
  final String courtName;
  final String location;
  final String distance;
  final String date;
  final String time;
  final int duration;
  final String minLevel;
  final String maxLevel;
  final int currentPlayers;
  final int totalPlayers;
  final int costPerPlayer;
  final String gender;
  final int rounds;

  bool get isFull => currentPlayers >= totalPlayers;
}

const _kEvents = [
  _AmericanoEvent(
    id: '1',
    type: 'فرق',
    courtName: 'نادي البادل الملكي',
    location: 'الدمام',
    distance: '1.8 كم',
    date: 'الاثنين، 3 يونيو',
    time: '5:00 مساءً',
    duration: 180,
    minLevel: '4.5',
    maxLevel: '6.0',
    currentPlayers: 10,
    totalPlayers: 16,
    costPerPlayer: 60,
    gender: 'رجال',
    rounds: 4,
  ),
  _AmericanoEvent(
    id: '2',
    type: 'فردي',
    courtName: 'بادل كلوب الشرقية',
    location: 'الخبر',
    distance: '3.2 كم',
    date: 'الثلاثاء، 4 يونيو',
    time: '6:30 مساءً',
    duration: 150,
    minLevel: '3.5',
    maxLevel: '5.0',
    currentPlayers: 6,
    totalPlayers: 8,
    costPerPlayer: 45,
    gender: 'رجال',
    rounds: 3,
  ),
  _AmericanoEvent(
    id: '3',
    type: 'فرق',
    courtName: 'مركز بادل المدينة',
    location: 'الدمام',
    distance: '5.4 كم',
    date: 'الأربعاء، 5 يونيو',
    time: '4:00 مساءً',
    duration: 200,
    minLevel: '5.0',
    maxLevel: '7.0',
    currentPlayers: 12,
    totalPlayers: 12,
    costPerPlayer: 70,
    gender: 'نساء',
    rounds: 5,
  ),
  _AmericanoEvent(
    id: '4',
    type: 'فردي',
    courtName: 'نادي النخبة',
    location: 'الخبر',
    distance: '2.3 كم',
    date: 'الخميس، 6 يونيو',
    time: '7:00 مساءً',
    duration: 120,
    minLevel: '4.0',
    maxLevel: '5.5',
    currentPlayers: 4,
    totalPlayers: 8,
    costPerPlayer: 50,
    gender: 'رجال',
    rounds: 3,
  ),
];

class AmericanoPage extends StatefulWidget {
  const AmericanoPage({super.key, this.onBack, this.onNavigate});

  final VoidCallback? onBack;
  final void Function(String page, [String? americanoType])? onNavigate;

  @override
  State<AmericanoPage> createState() => _AmericanoPageState();
}

class _AmericanoPageState extends State<AmericanoPage> {
  String _search = '';

  List<_AmericanoEvent> get _filtered {
    if (_search.isEmpty) return _kEvents;
    final q = _search.toLowerCase();
    return _kEvents
        .where((e) =>
            e.courtName.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q) ||
            e.type.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                  vertical: AppSizes.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterChips(),
                    const SizedBox(height: AppSizes.lg),
                    _buildInfoCard(),
                    const SizedBox(height: AppSizes.lg),
                    ..._filtered
                        .map((e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSizes.lg),
                              child: _EventCard(
                                event: e,
                                onNavigate: widget.onNavigate,
                              ),
                            )),
                    _buildBottomCreateButton(),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GradientPageHeader(
      title: 'أمريكانو',
      subtitle: 'نظام المباريات الدوري مع تبديل الشركاء',
      onBack: widget.onBack,
      trailing: [
        _HeaderCreateButton(
          onTap: () => widget.onNavigate?.call('create-americano'),
        ),
      ],
      bottom: AppSearchField(
        hint: 'ابحث عن أمريكانو...',
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _FilterChip(label: 'الكل', selected: true),
          SizedBox(width: AppSizes.sm),
          _FilterChip(label: 'النوع'),
          SizedBox(width: AppSizes.sm),
          _FilterChip(label: 'المستوى'),
          SizedBox(width: AppSizes.sm),
          _FilterChip(label: 'التاريخ'),
          SizedBox(width: AppSizes.sm),
          _FilterChip(label: 'الموقع'),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGreen50, Color(0x80DCF4E7)],
        ),
        border: Border.all(color: _kGreen500.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: _kGreen500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(Icons.trending_up,
                color: _kGreen600, size: AppSizes.iconMd),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ما هو الأمريكانو؟',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _kGreen600,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  'نظام تنافسي يلعب فيه كل لاعب مع شركاء مختلفين في كل جولة. يتم احتساب النقاط بشكل فردي والفائز هو من يجمع أعلى نقاط في النهاية.',
                  style: AppTextStyles.caption.copyWith(
                    color: _kGreen600.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCreateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGreen500, _kGreen600],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: _kGreen500.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: () => widget.onNavigate?.call('create-americano'),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: AppSizes.iconMd, color: Colors.white),
                SizedBox(width: AppSizes.sm),
                Text(
                  'أنشئ أمريكانو جديد',
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

class _HeaderCreateButton extends StatelessWidget {
  const _HeaderCreateButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kGreen500,
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
              const Icon(Icons.add, size: AppSizes.iconMd, color: Colors.white),
              SizedBox(width: AppSizes.xs),
              Text(
                'إنشاء',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

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
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  selected ? AppColors.onPrimary : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.onNavigate});

  final _AmericanoEvent event;
  final void Function(String page, [String? americanoType])? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadgeRow(),
            const SizedBox(height: AppSizes.md),
            _buildLocationRow(),
            const SizedBox(height: AppSizes.md),
            _buildDateTimeRow(),
            const SizedBox(height: AppSizes.md),
            _buildDetailsBox(),
            const SizedBox(height: AppSizes.md),
            _buildAvatarRow(),
            SizedBox(height: AppSizes.md),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRow() {
    final isTeam = event.type == 'فرق';
    final typeBg = isTeam ? _kPurple50 : _kBlue50;
    final typeFg = isTeam ? _kPurple600 : _kBlue600;
    final remaining = event.totalPlayers - event.currentPlayers;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.xs),
          decoration: BoxDecoration(
            color: typeBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(event.type,
              style: AppTextStyles.caption.copyWith(
                  color: typeFg, fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.xs),
          decoration: BoxDecoration(
            color: _kGray100,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(event.gender,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedForeground)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.xs),
          decoration: BoxDecoration(
            color: event.isFull
                ? _kRed50
                : _kGreen50,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            event.isFull ? 'مكتمل' : 'متبقي $remaining',
            style: AppTextStyles.caption.copyWith(
              color: event.isFull ? _kRed600 : _kGreen600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: AppSizes.iconSm, color: AppColors.mutedForeground),
        SizedBox(width: AppSizes.xs),
        Expanded(
          child: Text(
            '${event.courtName} · ${event.location}',
            style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          event.distance,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoCell(
            icon: Icons.calendar_today_outlined,
            label: event.date,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _InfoCell(
            icon: Icons.access_time_outlined,
            label: event.time,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsBox() {
    final durationHours = (event.duration / 60).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: _kGray50,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: _kGray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DetailItem(
                label: 'المستوى',
                value: '${event.minLevel}-${event.maxLevel}'),
          ),
          _DetailItem(
              label: 'الجولات', value: '${event.rounds}'),
          const SizedBox(width: AppSizes.md),
          _DetailItem(
              label: 'المدة', value: '$durationHours س'),
          const SizedBox(width: AppSizes.md),
          _DetailItem(
              label: 'اللاعبون',
              value: '${event.currentPlayers}/${event.totalPlayers}'),
        ],
      ),
    );
  }

  Widget _buildAvatarRow() {
    const maxVisible = 5;
    final visible = event.currentPlayers > maxVisible
        ? maxVisible
        : event.currentPlayers;
    final overflow = event.currentPlayers > maxVisible
        ? event.currentPlayers - maxVisible
        : 0;

    return Row(
      children: [
        for (int i = 0; i < visible; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                '${i + 1}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _kGray200,
              child: Text(
                '+$overflow',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        const Spacer(),
        Text(
          '${event.currentPlayers} / ${event.totalPlayers} لاعب',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التكلفة للاعب',
                style: AppTextStyles.caption),
            Text(
              '${event.costPerPlayer} ر.س',
              style: AppTextStyles.bodySmall.copyWith(
                color: _kGreen600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (event.isFull)
          _GreenGradientButton(
            label: 'إدارة الأمريكانو',
            icon: Icons.settings_outlined,
            onTap: () =>
                onNavigate?.call('americano-execution'),
          )
        else
          _PrimaryGradientButton(
            label: 'انضم الآن',
            icon: Icons.login_outlined,
            onTap: () =>
                onNavigate?.call('join-americano', event.type),
          ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
        SizedBox(width: AppSizes.xs),
        Flexible(
          child: Text(label,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontSize: 10)),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondary)),
      ],
    );
  }
}

class _GreenGradientButton extends StatelessWidget {
  const _GreenGradientButton(
      {required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen500, _kGreen600],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: _kGreen500.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.iconSm, color: Colors.white),
                SizedBox(width: AppSizes.xs),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton(
      {required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.iconSm, color: Colors.white),
                SizedBox(width: AppSizes.xs),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.onPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
