import 'package:flutter/material.dart';

import '../widgets/policy_page_scaffold.dart';
import '../../../../core/localization/tr_global.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PolicyPageScaffold(
      onBack: onBack,
      settingKey: 'privacy_policy',
      titleAr: trg('سياسة الخصوصية'),
      titleEn: 'Privacy Policy',
      infoIcon: Icons.shield_outlined,
    );
  }
}
