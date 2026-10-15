import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/membership_repository.dart';
import '../../domain/entities/membership.dart';
import 'membership_benefits.dart';

/// نموذج إضافة/تعديل خطة عضوية (ورقة سفلية). يعيد الخطة المحفوظة.
Future<MembershipPlan?> showMembershipPlanSheet(
  BuildContext context, {
  required int venueId,
  required double sportaFeePercent,
  MembershipPlan? plan,
}) {
  return showModalBottomSheet<MembershipPlan>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PlanSheet(
      venueId: venueId,
      sportaFeePercent: sportaFeePercent,
      plan: plan,
    ),
  );
}

class _PlanSheet extends StatefulWidget {
  const _PlanSheet({
    required this.venueId,
    required this.sportaFeePercent,
    this.plan,
  });

  final int venueId;
  final double sportaFeePercent;
  final MembershipPlan? plan;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late final _name = TextEditingController(text: widget.plan?.nameAr ?? '');
  late final _nameEn = TextEditingController(text: widget.plan?.nameEn ?? '');
  late final _desc = TextEditingController(
    text: widget.plan?.description ?? '',
  );
  late final _price = TextEditingController(
    text: widget.plan == null ? '' : money(widget.plan!.monthlyPrice),
  );
  late double _discount = widget.plan?.discountPercent ?? 15;
  late bool _capped = widget.plan?.monthlyDiscountHours != null;
  late int _capHours = widget.plan?.monthlyDiscountHours ?? 8;
  late int _priority = widget.plan?.priorityDays ?? 7;
  late bool _active = widget.plan?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  double get _priceValue => double.tryParse(_price.text.trim()) ?? 0;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    String? problem;
    if (_name.text.trim().isEmpty) {
      problem = context.tr('اكتب اسم الخطة');
    } else if (_priceValue <= 0) {
      problem = context.tr('حدّد سعراً شهرياً صحيحاً');
    } else if (_discount <= 0 && _priority <= 0) {
      problem = context.tr('أضف خصماً أو أيام أولوية على الأقل');
    }
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final saved = await getIt<MembershipRepository>().savePlan(
        venueId: widget.venueId,
        planId: widget.plan?.id,
        name: _name.text.trim(),
        nameEn: _nameEn.text.trim().isEmpty ? null : _nameEn.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        monthlyPrice: _priceValue,
        discountPercent: _discount,
        monthlyDiscountHours: _capped && _discount > 0 ? _capHours : null,
        priorityDays: _priority,
        isActive: _active,
      );
      navigator.pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final net = _priceValue * (1 - widget.sportaFeePercent / 100);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                widget.plan == null
                    ? context.tr('خطة عضوية جديدة')
                    : context.tr('تعديل خطة العضوية'),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: context.tr('اسم الخطة'),
                hint: context.tr('مثال: العضوية الذهبية'),
                controller: _name,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: context.tr('الاسم بالإنجليزية (اختياري)'),
                hint: 'Gold',
                controller: _nameEn,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: context.tr('وصف قصير (اختياري)'),
                controller: _desc,
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.tr('السعر الشهري'),
                  suffixText: context.tr('ر.س'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_priceValue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(
                    context.trArgs(
                      'تستلم {p0} ر.س عن كل عضو شهرياً (بعد نسبة سبورتا {p1}%)',
                      {'p0': money(net), 'p1': money(widget.sportaFeePercent)},
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.lg),
              _label(
                context.trArgs('خصم الحجز: {p0}%', {'p0': money(_discount)}),
              ),
              Slider(
                value: _discount,
                max: 50,
                divisions: 10,
                label: '${money(_discount)}%',
                activeColor: membershipGold,
                onChanged: (v) => setState(() => _discount = v),
              ),
              Text(
                context.tr(
                  'الخصم من سعرك أنت، ونسبة سبورتا تُحسب على السعر بعد الخصم.',
                ),
                style: AppTextStyles.caption,
              ),
              if (_discount > 0) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _capped,
                  activeTrackColor: membershipGold,
                  title: Text(
                    context.tr('سقف شهري لساعات الخصم'),
                    style: AppTextStyles.bodySmall,
                  ),
                  onChanged: (v) => setState(() => _capped = v),
                ),
                if (_capped)
                  _stepper(
                    context.trArgs('{p0} ساعات في الشهر', {'p0': _capHours}),
                    onMinus: _capHours > 1
                        ? () => setState(() => _capHours--)
                        : null,
                    onPlus: () => setState(() => _capHours++),
                  ),
              ],
              const SizedBox(height: AppSizes.lg),
              _label(context.tr('أولوية الحجز')),
              const SizedBox(height: AppSizes.xs),
              _stepper(
                _priority == 0
                    ? context.tr('بلا أولوية')
                    : context.trArgs('يحجز قبل غيره بـ {p0} أيام', {
                        'p0': _priority,
                      }),
                onMinus: _priority > 0
                    ? () => setState(() => _priority--)
                    : null,
                onPlus: _priority < 60
                    ? () => setState(() => _priority++)
                    : null,
              ),
              Text(
                context.tr(
                  'تعمل الأولوية حين تحدّد «نافذة الحجز» للنادي — العضو يرى أياماً إضافية فوقها.',
                ),
                style: AppTextStyles.caption,
              ),
              if (widget.plan != null)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  title: Text(
                    context.tr('متاحة للاشتراك'),
                    style: AppTextStyles.bodySmall,
                  ),
                  subtitle: Text(
                    context.tr('الإيقاف يمنع الاشتراكات الجديدة والتجديد'),
                    style: AppTextStyles.caption,
                  ),
                  onChanged: (v) => setState(() => _active = v),
                ),
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.tr('حفظ الخطة')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _stepper(String text, {VoidCallback? onMinus, VoidCallback? onPlus}) =>
      Row(
        children: [
          IconButton.outlined(
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton.outlined(
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      );
}
