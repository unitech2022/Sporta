import 'package:flutter/material.dart';

import '../widgets/policy_page_scaffold.dart';
import '../../../../core/localization/tr_global.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PolicyPageScaffold(
      onBack: onBack,
      settingKey: 'refund_policy',
      titleAr: trg('سياسة الاسترجاع'),
      titleEn: 'Refund Policy',
      infoIcon: Icons.attach_money,
    );
  }
}
