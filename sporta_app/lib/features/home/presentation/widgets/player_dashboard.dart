import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../level/domain/level_question.dart';
import 'points_banner.dart';

const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF22C55E);
const _orange = Color(0xFFF97316);
const _purple = Color(0xFFA855F7);
const _yellow = Color(0xFFEAB308);

/// Player home dashboard: points banner, courts map, community pulse,
/// tournaments and friend activity.
class PlayerDashboard extends StatefulWidget {
  const PlayerDashboard({
    super.key,
    required this.onOpenPoints,
    required this.onOpenCourts,
  });

  final VoidCallback onOpenPoints;
  final VoidCallback onOpenCourts;

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  final Set<int> _friendRequests = {};

  @override
  Widget build(BuildContext context) {
    final user = context.auth.user;
    final showLevel = user?.levelAssessed == true && user?.level != null;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLevel) ...[
            _LevelCard(level: user!.level!),
            const SizedBox(height: AppSizes.xxl),
          ],
          PointsBanner(onTap: widget.onOpenPoints),
          const SizedBox(height: AppSizes.xxl),
          _sectionTitle('خريطة الملاعب الرياضية'),
          _CourtsMapCard(onTap: widget.onOpenCourts),
          const SizedBox(height: AppSizes.xxl),
          _sectionTitle('نبض المجتمع الرياضي', viewAll: true),
          const _PulseTile(
            color: _orange,
            icon: Icons.local_fire_department,
            richText: [('أحمد', true), (' وصل لمستوى ', false), ('6', true)],
            time: 'منذ ساعتين',
          ),
          const SizedBox(height: AppSizes.md),
          const _PulseTile(
            color: _yellow,
            icon: Icons.emoji_events,
            richText: [
              ('منذر', true),
              (' حقق ', false),
              ('6', true),
              (' نقاط خلال اليوم', false),
            ],
            time: 'منذ 3 ساعات',
          ),
          const SizedBox(height: AppSizes.md),
          const _PulseTile(
            color: _blue,
            icon: Icons.bolt,
            richText: [
              ('محمد', true),
              (' يبحث عن شريك لمباراة الآن بعد ساعة', false),
            ],
            time: 'منذ 15 دقيقة',
            actionLabel: 'انضم للمباراة',
          ),
          const SizedBox(height: AppSizes.md),
          const _PulseTile(
            color: _purple,
            icon: Icons.chat_bubble_outline,
            richText: [
              ('أكثر من ', false),
              ('15', true),
              (' لاعب رفعوا مستواهم اليوم', false),
            ],
            time: 'منذ 30 دقيقة',
          ),
          const SizedBox(height: AppSizes.xxl),
          _sectionTitle('بطولات البادل'),
          const _TournamentGroup(
            icon: Icons.public,
            iconColor: Color(0xFF2563EB),
            title: 'البطولات الدولية',
            tournaments: [
              _Tournament('بطولة دبي المفتوحة للبادل', '15 - 20 يوليو 2026',
                  'دبي، الإمارات العربية المتحدة', 'الجائزة الكبرى',
                  r'$100,000', Color(0xFF2563EB), tinted: true),
              _Tournament('كأس العالم للبادل 2026', '10 - 18 أغسطس 2026',
                  'مدريد، إسبانيا', 'الجائزة الكبرى', r'$250,000',
                  AppColors.primary),
              _Tournament('بطولة قطر الدولية للبادل', '5 - 10 سبتمبر 2026',
                  'الدوحة، قطر', 'الجائزة الكبرى', r'$75,000',
                  Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          const _TournamentGroup(
            icon: Icons.military_tech,
            iconColor: Color(0xFF16A34A),
            title: 'البطولات المحلية',
            tournaments: [
              _Tournament('بطولة الرياض الكبرى للبادل', '25 - 28 يونيو 2026',
                  'نادي البادل الملكي، الرياض', 'الجائزة', '50,000 ر.س',
                  Color(0xFF16A34A), tinted: true),
              _Tournament('كأس جدة للبادل', '10 - 12 يوليو 2026',
                  'نادي الشاطئ، جدة', 'الجائزة', '30,000 ر.س',
                  Color(0xFFEA580C)),
              _Tournament('بطولة الدمام المفتوحة', '20 - 22 يوليو 2026',
                  'مركز الدمام الرياضي، الدمام', 'الجائزة', '25,000 ر.س',
                  Color(0xFF9333EA)),
            ],
          ),
          SizedBox(height: AppSizes.xxl),
          _sectionTitle('نشاط الأصدقاء'),
          Text('آخر أصدقائهم',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          const _FriendActivityTile(
            color: _blue,
            initial: 'أ',
            richText: [('أحمد', true), (' حجز ملعباً', false)],
            details: 'نادي البادل الملكي  •  غداً، 5:00 مساءً',
            time: 'منذ 10 دقائق',
          ),
          const SizedBox(height: AppSizes.md),
          const _FriendActivityTile(
            color: _orange,
            initial: 'ن',
            richText: [('ناصر', true), (' يبحث عن فريق', false)],
            details: 'أمريكانو  •  اليوم، 7:00 مساءً',
            time: 'منذ 25 دقيقة',
          ),
          SizedBox(height: AppSizes.md),
          const _FriendActivityTile(
            color: _yellow,
            initial: 'س',
            richText: [('سعود', true), (' فاز في بطولة', false)],
            details: '🏆 بطولة الرياض المحلية',
            time: 'منذ ساعة',
          ),
          SizedBox(height: AppSizes.md),
          const _FriendActivityTile(
            color: _green,
            initial: 'ع',
            richText: [
              ('عبدالرحمن', true),
              (' رفع مستواه إلى ', false),
              ('5.0', true),
            ],
            details: '★★★★★',
            time: 'منذ ساعتين',
          ),
          SizedBox(height: AppSizes.xl),
          Text('اقتراحات لك',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          _suggestion(1, 'محمد العتيبي', '4.5', 'الرياض',
              'مستوى قريب منك', AppColors.primary, AppColors.primary),
          const SizedBox(height: AppSizes.md),
          _suggestion(2, 'عبدالله الشمري', '3.5', 'الرياض',
              'يلعب في ملعبك المفضل', _green, const Color(0xFF16A34A)),
          SizedBox(height: AppSizes.md),
          _suggestion(3, 'خالد المطيري', '5.0', 'جدة',
              '3 أصدقاء مشتركين', _blue, const Color(0xFF2563EB)),
          SizedBox(height: AppSizes.md),
          _suggestion(4, 'سعد القحطاني', '4.0', 'الرياض',
              'لعب مع صديقك أحمد', _orange, const Color(0xFFEA580C)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {bool viewAll = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.secondary)),
          ),
          if (viewAll)
            Text('عرض الكل',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _suggestion(int id, String name, String level, String city,
      String hint, Color avatarColor, Color hintColor) {
    final sent = _friendRequests.contains(id);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(name.characters.first,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: AppSizes.iconSm, color: _yellow),
                    SizedBox(width: AppSizes.xs),
                    Flexible(
                      child: Text('مستوى $level  •  $city',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.xs),
                Text(hint,
                    style: AppTextStyles.caption.copyWith(color: hintColor)),
              ],
            ),
          ),
          if (sent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text('تم الإرسال',
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFF4B5563))),
            )
          else
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: InkWell(
                onTap: () => setState(() => _friendRequests.add(id)),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt,
                          size: 12, color: Colors.white),
                      SizedBox(width: AppSizes.xs),
                      Text('إضافة',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows the player's current level, read from the authenticated user.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final lang = context.appSettings.language;
    final name = playerLevelName(level, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$level',
                style: AppTextStyles.heading1
                    .copyWith(color: Colors.white, fontSize: 28)),
          ),
          const SizedBox(width: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('yourLevel'),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: AppSizes.xs),
              Text(name,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourtsMapCard extends StatelessWidget {
  const _CourtsMapCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 256,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFDBEAFE),
                      Color(0xFFEFF6FF),
                      Color(0xFFF0FDF4),
                    ],
                  ),
                ),
              ),
              CustomPaint(painter: _MapGridPainter()),
              const Align(
                alignment: Alignment(0.5, -0.4),
                child: _MapPin(color: AppColors.primary, size: 32,
                    label: 'نادي البادل الملكي'),
              ),
              const Align(
                alignment: Alignment(-0.4, 0.05),
                child: _MapPin(color: _green),
              ),
              const Align(
                alignment: Alignment(0.35, 0.5),
                child: _MapPin(color: _orange),
              ),
              const Align(
                alignment: Alignment(-0.5, -0.5),
                child: _MapPin(color: _purple),
              ),
              const Align(
                alignment: Alignment(0, 0.35),
                child: _MapPin(color: _blue),
              ),
              PositionedDirectional(
                bottom: AppSizes.lg,
                start: AppSizes.lg,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg, vertical: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: AppSizes.iconSm, color: AppColors.primary),
                      SizedBox(width: AppSizes.sm),
                      Text('8 ملاعب قريبة',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSizes.lg,
                start: AppSizes.lg,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(Icons.map_outlined,
                      size: AppSizes.iconMd, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, size.height * f),
          Offset(size.width, size.height * f), paint);
      canvas.drawLine(Offset(size.width * f, 0),
          Offset(size.width * f, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, this.size = 28, this.label});

  final Color color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final pin = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(Icons.location_on, size: size * 0.45, color: Colors.white),
    );

    if (label == null) return pin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm, vertical: AppSizes.xs),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(label!,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.secondary)),
        ),
        const SizedBox(height: AppSizes.xs),
        pin,
      ],
    );
  }
}

/// Community pulse feed tile with a colored leading icon circle.
class _PulseTile extends StatelessWidget {
  const _PulseTile({
    required this.color,
    required this.icon,
    required this.richText,
    required this.time,
    this.actionLabel,
  });

  final Color color;
  final IconData icon;
  final List<(String, bool)> richText;
  final String time;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Icon(icon, size: AppSizes.iconMd, color: Colors.white),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      for (final (text, bold) in richText)
                        TextSpan(
                          text: text,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight:
                                bold ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(time, style: AppTextStyles.caption),
                if (actionLabel != null) ...[
                  SizedBox(height: AppSizes.sm),
                  Material(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md, vertical: 6),
                        child: Text(actionLabel!,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendActivityTile extends StatelessWidget {
  const _FriendActivityTile({
    required this.color,
    required this.initial,
    required this.richText,
    required this.details,
    required this.time,
  });

  final Color color;
  final String initial;
  final List<(String, bool)> richText;
  final String details;
  final String time;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      for (final (text, bold) in richText)
                        TextSpan(
                          text: text,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight:
                                bold ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.sm),
                Text(details, style: AppTextStyles.caption),
                SizedBox(height: AppSizes.xs),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tournament {
  const _Tournament(this.name, this.dates, this.location, this.prizeLabel,
      this.prize, this.color,
      {this.tinted = false});

  final String name;
  final String dates;
  final String location;
  final String prizeLabel;
  final String prize;
  final Color color;
  final bool tinted;
}

class _TournamentGroup extends StatelessWidget {
  const _TournamentGroup({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tournaments,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_Tournament> tournaments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppSizes.iconMd, color: iconColor),
            SizedBox(width: AppSizes.sm),
            Text(title,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.secondary)),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        for (final tournament in tournaments) ...[
          if (tournament != tournaments.first)
            SizedBox(height: AppSizes.md),
          _TournamentCard(tournament: tournament),
        ],
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament});

  final _Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final card = Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tournament.name,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: AppSizes.xs),
                  _detailRow(Icons.calendar_today_outlined, tournament.dates),
                  SizedBox(height: AppSizes.xs),
                  _detailRow(Icons.location_on_outlined, tournament.location),
                ],
              ),
            ),
            Icon(Icons.emoji_events, size: 32, color: tournament.color),
          ],
        ),
        SizedBox(height: AppSizes.md),
        const Divider(height: 1),
        SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tournament.prizeLabel, style: AppTextStyles.caption),
            Text(tournament.prize,
                style: AppTextStyles.bodySmall.copyWith(
                    color: tournament.color, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );

    if (tournament.tinted) {
      return TintedCard(tint: tournament.color, child: card);
    }
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: card,
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        SizedBox(width: AppSizes.sm),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
