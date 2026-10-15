import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../data/membership_repository.dart';
import '../../domain/entities/membership.dart';

/// حصة المستخدم في مباراة/أمريكانو/بطولة قائمة بعد خصم عضويته في نادي
/// الملعب. يعود السعر الأصلي إن لم يكن عضواً أو تعذّر السؤال — الخادم يحسب
/// الخصم عند الدفع في كل الأحوال، وهذا للعرض قبل التأكيد فقط.
Future<MemberShareQuote> eventShareQuote({
  int? matchId,
  int? americanoId,
  required double price,
}) async {
  if (price <= 0) return MemberShareQuote.full(price);
  try {
    return await getIt<MembershipRepository>().fetchEventShare(
      matchId: matchId,
      americanoId: americanoId,
    );
  } catch (_) {
    return MemberShareQuote.full(price);
  }
}

/// حصة منشئ حدث جديد على ملعب بعد خصم عضويته (قبل الإنشاء).
Future<MemberShareQuote> courtShareQuote({
  required int courtId,
  required double price,
  required int minutes,
}) async {
  if (price <= 0 || courtId <= 0) return MemberShareQuote.full(price);
  try {
    return await getIt<MembershipRepository>().fetchCourtShare(
      courtId: courtId,
      price: price,
      minutes: minutes,
    );
  } catch (_) {
    return MemberShareQuote.full(price);
  }
}

/// سطرا «السعر الأصلي» و«خصم عضوية النادي» لحوار تأكيد الدفع (فارغة بلا خصم).
List<PaymentDetail> memberShareDetails(
  BuildContext context,
  MemberShareQuote q,
) => q.hasDiscount
    ? [
        PaymentDetail(
          context.tr('السعر الأصلي للحصة'),
          context.trArgs('{p0} ر.س', {'p0': money(q.price)}),
        ),
        PaymentDetail(
          context.tr('خصم عضوية النادي'),
          context.trArgs('- {p0} ر.س', {'p0': money(q.discount)}),
        ),
      ]
    : const [];
