import 'package:flutter/widgets.dart';

/// يطلب الصفحة التالية من قائمة مقسّمة ([onLoadMore]) حين يقترب المستخدم من
/// آخرها بالتمرير — **وأيضاً** حين تتغير أبعاد المحتوى فتبقى القائمة أقصر من
/// الشاشة (دفعة أولى لا تملؤها على شاشة طويلة أو تابلت)، وإلا لا تمرير فلا
/// تُحمَّل البقية أبداً.
///
/// يستمع للقائمة التي يلفّها مباشرة فقط (`depth == 0`)، فلا تُطلق التحميلَ
/// قوائمُ أفقية داخلها. [onLoadMore] يجب أن يتجاهل الطلب المكرّر (أثناء
/// التحميل أو حين لا مزيد).
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 200,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  /// المسافة المتبقية حتى آخر القائمة التي يبدأ عندها التحميل.
  final double threshold;

  bool _nearEnd(ScrollMetrics m) =>
      m.axis == Axis.vertical && m.maxScrollExtent - m.pixels <= threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.depth == 0 && _nearEnd(n.metrics)) onLoadMore();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 && _nearEnd(n.metrics)) onLoadMore();
          return false;
        },
        child: child,
      ),
    );
  }
}
