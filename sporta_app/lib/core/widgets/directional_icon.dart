import 'package:flutter/material.dart';

/// An [Icon] whose glyph mirrors with the ambient text direction — use for
/// chevrons/arrows so back & disclosure indicators point correctly in both
/// RTL (Arabic) and LTR (English). Has a const constructor so it can sit inside
/// const widget subtrees.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon({
    super.key,
    required this.rtl,
    required this.ltr,
    this.size,
    this.color,
  });

  final IconData rtl;
  final IconData ltr;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // أسهم ماتيريال (chevron/arrow) معلّمة بـ matchTextDirection، فتنعكس
    // تلقائيًا في الواجهة العربية. نثبّت اتجاه الرسم على LTR حتى تظهر
    // الأيقونة كما اختارها كل استدعاء تمامًا بدل أن تنقلب مرّتين.
    return Icon(
      isRtl ? rtl : ltr,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}
