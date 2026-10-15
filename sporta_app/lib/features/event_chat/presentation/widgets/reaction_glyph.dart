import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';

/// رموز التفاعل السريع (تُخزَّن في الخادم كإيموجي قياسي).
const List<String> kChatReactions = ['👍', '❤️', '😂', '🔥', '👏'];

/// يرسم رمز التفاعل بأيقونة ملوّنة من أيقونات التطبيق بدل الإيموجي: بعض
/// البيئات (منها محاكي iOS 26 مع Flutter) لا ترسم إيموجي الألوان فيظهر
/// مربّعاً بعلامة استفهام. رمز غير معروف يُعرض نصاً كما هو.
class ReactionGlyph extends StatelessWidget {
  const ReactionGlyph({super.key, required this.emoji, this.size = 18});

  final String emoji;
  final double size;

  static (IconData, Color)? iconFor(String emoji) => switch (emoji) {
    '👍' => (Icons.thumb_up_rounded, const Color(0xFF2563EB)),
    '❤️' || '❤' => (Icons.favorite_rounded, const Color(0xFFEF4444)),
    '😂' => (Icons.sentiment_very_satisfied_rounded, const Color(0xFFF59E0B)),
    '🔥' => (Icons.local_fire_department_rounded, const Color(0xFFF97316)),
    '👏' => (Icons.celebration_rounded, const Color(0xFF8B5CF6)),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final icon = iconFor(emoji);
    if (icon == null) {
      return Text(
        emoji,
        style: TextStyle(
          fontSize: size * 0.85,
          fontFamilyFallback: AppTextStyles.emojiFallback,
        ),
      );
    }
    return Icon(icon.$1, size: size, color: icon.$2);
  }
}
