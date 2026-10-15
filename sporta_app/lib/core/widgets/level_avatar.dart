import 'package:flutter/material.dart';

import '../localization/tr_global.dart';
import 'network_circle_avatar.dart';

/// هوية مستويات اللاعب السبعة على طريقة رُتب الألعاب: معادن ثم أحجار
/// كريمة ثم الماس للنخبة. لكل مستوى تدرّج يُرسم به إطار الصورة ودائرة الرقم،
/// ولون أساسي داكن يصلح للنصوص (اسم المستوى).
abstract class PlayerLevelStyle {
  static const List<List<Color>> _gradients = [
    [Color(0xFFF3C69B), Color(0xFFC07A3C), Color(0xFF8C5225)], // 1 برونزي
    [Color(0xFFF1F5F9), Color(0xFFAAB4C3), Color(0xFF6B7789)], // 2 فضّي
    [Color(0xFFFFE8A3), Color(0xFFF2B705), Color(0xFFB7791F)], // 3 ذهبي
    [Color(0xFF8EF0C8), Color(0xFF10B981), Color(0xFF047857)], // 4 زمرّدي
    [Color(0xFFA5C8FF), Color(0xFF3B82F6), Color(0xFF1E40AF)], // 5 ياقوتي أزرق
    [Color(0xFFE3C2FF), Color(0xFFA855F7), Color(0xFF6B21A8)], // 6 جمشتي
    [
      Color(0xFF5EEAD4),
      Color(0xFF818CF8),
      Color(0xFFE879F9),
      Color(0xFFFB7185),
    ], // 7 ماسي
  ];

  /// اللون الأساسي لكل مستوى (للنصوص والظل).
  static const List<Color> _colors = [
    Color(0xFFA9652F),
    Color(0xFF64748B),
    Color(0xFFC88A04),
    Color(0xFF059669),
    Color(0xFF2563EB),
    Color(0xFF9333EA),
    Color(0xFFC026D3),
  ];

  static const List<String> _names = [
    'مبتدئ',
    'ناشئ',
    'متعلّم',
    'متوسط',
    'متقدم',
    'محترف',
    'نخبة',
  ];

  static int _index(int level) => level.clamp(1, 7) - 1;

  static Color color(int level) => _colors[_index(level)];

  /// اسم المستوى مترجماً.
  static String name(int level) => trg(_names[_index(level)]);

  /// تدرّج الإطار والشارة.
  static List<Color> gradient(int level) => _gradients[_index(level)];

  /// النخبة بتدرّج دائري (ماسي) يلتفّ حول الصورة؛ البقية بتدرّج مائل لامع.
  static Gradient ringGradient(int level) {
    final colors = gradient(level);
    if (_index(level) == 6) {
      return SweepGradient(colors: [...colors, colors.first]);
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static Gradient badgeGradient(int level) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _index(level) == 6
        ? [gradient(level)[1], gradient(level)[2], gradient(level)[3]]
        : [gradient(level)[0], gradient(level)[1], gradient(level)[2]],
  );
}

/// صورة لاعب دائرية بإطار بلون مستواه ودائرة صغيرة بالرقم أسفلها في
/// المنتصف. بلا [level] تُعرض الصورة بإطار محايد بلا شارة (مدرب، أو لاعب لم
/// يُحدَّد مستواه).
///
/// الشارة تتدلّى نصفها تحت الدائرة، فيأخذ الويدجت مساحة سفلية إضافية بقدرها
/// حتى لا تتراكب مع ما تحته (الاسم مثلاً).
class LevelAvatar extends StatelessWidget {
  const LevelAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.level,
    this.radius = 24,
    this.fallbackColor,
    this.showBadge = true,
  });

  final String name;
  final String? imageUrl;

  /// 1..7 أو null.
  final int? level;

  /// نصف قطر الصورة نفسها (بدون الإطار).
  final double radius;

  /// خلفية الحرف البديل حين لا صورة (افتراضياً لون المستوى).
  final Color? fallbackColor;

  /// إخفاء دائرة الرقم مع إبقاء الإطار الملوّن (للأحجام الصغيرة جداً).
  final bool showBadge;

  double get _ring => (radius * 0.11).clamp(2.5, 4.5);
  double get _gap => (radius * 0.06).clamp(1.5, 3.0);
  double get _badge => (radius * 0.72).clamp(16.0, 30.0);

  @override
  Widget build(BuildContext context) {
    final lvl = level;
    final ringColor = lvl == null
        ? const Color(0xFFE2E8F0)
        : PlayerLevelStyle.color(lvl);
    final outer = radius + _gap + _ring;
    final badgeVisible = showBadge && lvl != null;

    final photo = NetworkCircleAvatar(
      imageUrl: imageUrl,
      radius: radius,
      // بلا صورة: خلفية فاتحة من لون المستوى والحرف بلونه — تبقى البطاقة
      // بلون واحد متناسق بدل ألوان عشوائية تتعارض مع الإطار.
      backgroundColor: lvl != null
          ? ringColor.withValues(alpha: 0.10)
          : (fallbackColor ?? const Color(0xFF94A3B8)),
      child: Text(
              name.trim().characters.firstOrNull ?? '؟',
              style: TextStyle(
                color: lvl != null
                    ? Color.lerp(ringColor, Colors.black, 0.15)
                    : Colors.white,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    final ring = Container(
      width: outer * 2,
      height: outer * 2,
      padding: EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lvl == null ? ringColor : null,
        gradient: lvl == null ? null : PlayerLevelStyle.ringGradient(lvl),
        boxShadow: lvl == null
            ? null
            : [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.30),
                  blurRadius: radius * 0.35,
                  offset: Offset(0, radius * 0.08),
                ),
              ],
      ),
      child: Container(
        padding: EdgeInsets.all(_gap),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: photo,
      ),
    );

    if (!badgeVisible) return ring;

    return Semantics(
      label: '${trg('المستوى')} $lvl · ${PlayerLevelStyle.name(lvl)}',
      child: SizedBox(
        width: outer * 2,
        height: outer * 2 + _badge / 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ring,
            Positioned(
              bottom: 0,
              child: Container(
                width: _badge,
                height: _badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PlayerLevelStyle.badgeGradient(lvl),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$lvl',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _badge * 0.52,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    // ظلّ خفيف يُبقي الرقم مقروءاً فوق الفضّي والذهبي الفاتحين.
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 2,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
