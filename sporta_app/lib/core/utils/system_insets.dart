import 'package:flutter/material.dart';

/// حشوات آمنة من شريط تنقّل النظام (أزرار أندرويد السفلية أو شريط الإيماءات،
/// و«الشريط الرئيسي» في آيفون).
///
/// التطبيق يعمل بوضع edge-to-edge (انظر `main.dart`)، أي أنه يرسم خلف شريطي
/// الحالة والتنقّل. لذلك يجب أن تُضيف كل صفحة ارتفاع الشريط السفلي إلى حشوتها
/// السفلية، وإلا اختفت نهاية المحتوى خلف أيقونات النظام.
///
/// ملاحظة مهمة: `MediaQuery.paddingOf` تُرجع صفرًا إذا كان الشريط السفلي
/// مستهلَكًا أصلًا — كصفحات التبويبات داخل [MainShell] (لأن `Scaffold` يخصم
/// الحشوة السفلية من `body` عند وجود `bottomNavigationBar`)، أو عند فتح لوحة
/// المفاتيح. فاستعمال هذه الامتدادات آمنٌ في كل مكان ولا يضيف فراغًا زائدًا.
extension SystemInsets on BuildContext {
  /// ارتفاع شريط تنقّل النظام الظاهر أسفل الشاشة (0 إن لم يكن هناك واحد).
  double get bottomSystemInset => MediaQuery.paddingOf(this).bottom;

  /// [padding] بعد إضافة ارتفاع شريط تنقّل النظام إلى حشوتها السفلية.
  /// تُستعمل مع حشوة قوائم الصفحات (`ListView`/`SingleChildScrollView`) وأشرطة
  /// الأزرار الثابتة في الأسفل.
  EdgeInsets safeBottom(EdgeInsets padding) =>
      padding.copyWith(bottom: padding.bottom + bottomSystemInset);
}
