import 'package:flutter/material.dart';

import '../widgets/policy_page_scaffold.dart';
import '../../../../core/localization/tr_global.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PolicyPageScaffold(
      onBack: onBack,
      settingKey: 'terms_conditions',
      titleAr: trg('الشروط والأحكام'),
      titleEn: 'Terms & Conditions',
      infoIcon: Icons.description_outlined,
    );
  }
}
