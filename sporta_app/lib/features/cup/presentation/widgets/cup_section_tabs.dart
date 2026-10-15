import 'package:flutter/material.dart';

import '../../../../core/widgets/section_tabs.dart';

/// أقسام صفحة البطولة: التفاصيل / الفرق / المجموعات / الإقصائيات / النتائج /
/// الطلبات (للمنظّم وحده).
enum CupTab { details, teams, groups, bracket, results, requests }

typedef CupTabSpec = SectionTabSpec<CupTab>;

/// شريط تبويب البطولة — الشكل المشترك في [SectionTabs]؛ أقسامها كثيرة فيصير
/// تمريراً أفقياً يمتد لحافتي الشاشة.
class CupSectionTabs extends StatelessWidget {
  const CupSectionTabs({
    super.key,
    required this.active,
    required this.tabs,
    required this.onChanged,
  });

  final CupTab active;
  final List<CupTabSpec> tabs;
  final ValueChanged<CupTab> onChanged;

  @override
  Widget build(BuildContext context) =>
      SectionTabs<CupTab>(active: active, tabs: tabs, onChanged: onChanged);
}
