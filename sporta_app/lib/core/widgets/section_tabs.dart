import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// تبويب واحد في [SectionTabs]: قيمته وأيقونته وعنوانه وعدّاد اختياري
/// (مثل 3/8 أو عدد الطلبات) يظهر فقاعةً صغيرة بجانب العنوان.
class SectionTabSpec<T> {
  const SectionTabSpec({
    required this.tab,
    required this.icon,
    required this.label,
    this.badge,
  });

  final T tab;
  final IconData icon;
  final String label;
  final String? badge;
}

/// شريط تبويب على خلفية الترويسة المتدرّجة — نفس الشكل في صفحات المباراة
/// والأمريكانو والبطولة: حبّة بيضاء للقسم النشط والباقي شفاف، كل التبويبات
/// بارتفاع واحد، والعدّاد فقاعة بجانب العنوان لا سطراً ثانياً.
///
/// حتى [maxEqualTabs] تبويبات تتقاسم العرض بالتساوي؛ أكثر من ذلك يصير الشريط
/// تمريراً أفقياً بعرض كل تبويب حسب محتواه ويُبقي التبويب النشط ظاهراً عند
/// اختياره. في وضع التمرير ضعه بعرض الشاشة كاملاً (خارج حشوة الصفحة) ومرّر
/// الحشوة في [scrollPadding]، فيمتد التمرير إلى الحافة ويبقى كله قابلاً للّمس.
class SectionTabs<T> extends StatefulWidget {
  const SectionTabs({
    super.key,
    required this.active,
    required this.tabs,
    required this.onChanged,
    this.maxEqualTabs = 3,
    this.scrollPadding = AppSizes.pagePadding,
  });

  final T active;
  final List<SectionTabSpec<T>> tabs;
  final ValueChanged<T> onChanged;

  /// أقصى عدد تبويبات يتقاسم العرض بالتساوي قبل التحوّل إلى التمرير.
  final int maxEqualTabs;

  /// حشوة أول تبويب وآخره داخل شريط التمرير — تساوي حشوة الصفحة فيصطفّ
  /// الشريط مع بقية الترويسة، ويمرّ التمرير حتى حافة الشاشة.
  final double scrollPadding;

  static const double height = 44;

  @override
  State<SectionTabs<T>> createState() => _SectionTabsState<T>();
}

class _SectionTabsState<T> extends State<SectionTabs<T>> {
  final Map<T, GlobalKey> _keys = {};

  GlobalKey _keyFor(T tab) => _keys.putIfAbsent(tab, GlobalKey.new);

  bool get _scrolls => widget.tabs.length > widget.maxEqualTabs;

  @override
  void didUpdateWidget(covariant SectionTabs<T> old) {
    super.didUpdateWidget(old);
    if (_scrolls && old.active != widget.active) _revealActive();
  }

  @override
  void initState() {
    super.initState();
    if (_scrolls) _revealActive();
  }

  /// يمرّر الشريط حتى يظهر التبويب النشط كاملاً (لا يختبئ خلف الحافة).
  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.active]?.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_scrolls) {
      return SizedBox(
        height: SectionTabs.height,
        child: Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSizes.sm),
              Expanded(child: _tab(widget.tabs[i], expand: true)),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: SectionTabs.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: widget.scrollPadding),
        itemCount: widget.tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) => _tab(widget.tabs[i], expand: false),
      ),
    );
  }

  Widget _tab(SectionTabSpec<T> spec, {required bool expand}) {
    final selected = spec.tab == widget.active;
    final fg = selected ? AppColors.primary : Colors.white;
    final radius = BorderRadius.circular(AppSizes.radiusFull);

    // بعرض محتواه دائماً: في التمرير يأخذ التبويب عرضه، وفي العرض المتساوي
    // يُصغَّر داخل FittedBox إن ضاق المكان.
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(spec.icon, size: 17, color: fg),
        const SizedBox(width: 6),
        Text(
          spec.label,
          maxLines: 1,
          style: AppTextStyles.bodySmall.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            height: 1.1,
          ),
        ),
        if (spec.badge != null) ...[
          const SizedBox(width: 6),
          _Badge(text: spec.badge!, selected: selected),
        ],
      ],
    );

    return AnimatedContainer(
      key: _keyFor(spec.tab),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: SectionTabs.height,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: radius,
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: () => widget.onChanged(spec.tab),
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expand ? AppSizes.sm : AppSizes.md,
            ),
            // بالعرض المتساوي قد يضيق المكان عن العنوان مع العدّاد، فيُصغَّر
            // المحتوى ليظهر كاملاً بدل أن يُقصّ العنوان بنقاط.
            child: expand
                ? Center(
                    child: FittedBox(fit: BoxFit.scaleDown, child: content),
                  )
                : content,
          ),
        ),
      ),
    );
  }
}

/// عدّاد التبويب: فقاعة صغيرة بلون التبويب.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      // «✓» لا يحويه خط التطبيق فيظهر «√» — يُرسم أيقونة.
      child: text == '✓'
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: selected ? AppColors.primary : Colors.white,
            )
          : Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : Colors.white,
              ),
            ),
    );
  }
}
