import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/image_upload_field.dart';
import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/domain/entities/coach_specialization_entity.dart';
import '../../../sports/data/sport_models.dart';
import '../../../sports/data/sport_repository.dart';
import '../../../venue/data/venue_repository.dart';
import '../../../venue/domain/entities/owner_venue.dart';
import '../../domain/entities/registration_data.dart';
import 'labeled_input.dart';
import '../../../../core/localization/tr_global.dart';

/// Registration step (shown only when a coach or venue role is selected):
/// collects the extra details needed to create the coach profile / venue.
class RoleDetailsStep extends StatefulWidget {
  const RoleDetailsStep({
    super.key,
    required this.data,
    required this.formKey,
  });

  final RegistrationData data;
  final GlobalKey<FormState> formKey;

  @override
  State<RoleDetailsStep> createState() => RoleDetailsStepState();
}

class RoleDetailsStepState extends State<RoleDetailsStep> {
  RegistrationData get _data => widget.data;

  late Future<List<SportEntity>> _sportsFuture =
      getIt<SportRepository>().fetchSports();
  late Future<List<CoachSpecializationEntity>> _specializationsFuture =
      getIt<CoachRepository>().fetchSpecializations();
  late Future<List<VenueOption>> _venuesFuture =
      getIt<VenueRepository>().fetchOptions();

  late final _hourlyRateCtrl =
      TextEditingController(text: _data.coachHourlyRate);
  late final _coachBioCtrl = TextEditingController(text: _data.coachBio);
  late final _coachNameEnCtrl =
      TextEditingController(text: _data.coachNameEn);
  late final _certificationsCtrl =
      TextEditingController(text: _data.coachCertifications);
  late final _packagePriceCtrl =
      TextEditingController(text: _data.coachPackagePrice);
  late final _ibanCtrl = TextEditingController(text: _data.bankIban);
  late final _bankNameCtrl = TextEditingController(text: _data.bankName);
  late final _accountHolderCtrl =
      TextEditingController(text: _data.bankAccountHolder);

  static List<(String, String)> get _experienceOptions => [
    ('lessThanYear', trg('أقل من سنة')),
    ('oneToThree', trg('1-3 سنوات')),
    ('threeToFive', trg('3-5 سنوات')),
    ('moreThanFive', trg('أكثر من 5 سنوات')),
  ];

  static List<(String, String)> get _dayOptions => [
    ('sat', trg('السبت')),
    ('sun', trg('الأحد')),
    ('mon', trg('الاثنين')),
    ('tue', trg('الثلاثاء')),
    ('wed', trg('الأربعاء')),
    ('thu', trg('الخميس')),
    ('fri', trg('الجمعة')),
  ];

  @override
  void dispose() {
    _hourlyRateCtrl.dispose();
    _coachBioCtrl.dispose();
    _coachNameEnCtrl.dispose();
    _certificationsCtrl.dispose();
    _packagePriceCtrl.dispose();
    _ibanCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  /// Called by the parent before advancing to the next step.
  bool validate() {
    final formOk = widget.formKey.currentState?.validate() ?? false;
    if (!formOk) return false;

    if (_data.needsCoachDetails) {
      String? missing;
      if (_data.coachNameEn.trim().isEmpty) {
        missing = context.tr('يرجى إدخال الاسم بالإنجليزية');
      } else if (_data.coachExperienceLevel == null) {
        missing = context.tr('يرجى اختيار سنوات الخبرة');
      } else if (_data.coachSpecializationIds.isEmpty) {
        missing = context.tr('يرجى اختيار تخصص واحد على الأقل');
      } else if (_data.coachTargetGender == null) {
        missing = context.tr('يرجى اختيار الفئة المستهدفة');
      } else if (_data.coachAvailableDays.isEmpty) {
        missing = context.tr('يرجى اختيار الأيام المتاحة للتدريب');
      } else if (_data.coachResidency == null) {
        missing = context.tr('يرجى اختيار الجنسية');
      } else if (_data.coachNationalIdFrontUrl?.isEmpty ?? true) {
        missing = context.tr('يرجى رفع صورة الهوية (الوجه الأمامي)');
      } else if (_data.coachNationalIdBackUrl?.isEmpty ?? true) {
        missing = context.tr('يرجى رفع صورة الهوية (الوجه الخلفي)');
      }
      if (missing != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(missing)));
        return false;
      }
    }

    // The owner's document uploads aren't Form fields, so gate them here.
    if (_data.needsVenueDetails) {
      String? missing;
      if (_data.venueCommercialRegistrationImageUrl?.isEmpty ?? true) {
        missing = context.tr('يرجى رفع صورة السجل التجاري');
      } else if (_data.venueOwnerIdImageUrl?.isEmpty ?? true) {
        missing = context.tr('يرجى رفع صورة الهوية');
      } else if (_data.venueTaxCertificateUrl?.isEmpty ?? true) {
        missing = context.tr('يرجى رفع صورة شهادة الضريبة');
      }
      if (missing != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(missing)));
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('roleDetailsTitle'),
            style: AppTextStyles.heading1.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr('roleDetailsSubtitle'),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSizes.xxl),
          if (_data.needsCoachDetails) ..._buildCoachSections(context),
          if (_data.needsCoachDetails && _data.needsVenueDetails)
            const SizedBox(height: AppSizes.xxl),
          if (_data.needsVenueDetails) _buildVenueSection(context),
          const SizedBox(height: AppSizes.xxl),
          _buildBankSection(context),
        ],
      ),
    );
  }

  // ── الحساب البنكي ─────────────────────────────────────────────────────────

  /// بيانات الحساب البنكي لاستلام المستحقات — قسم واحد مشترك مهما تعددت
  /// الأدوار، لأن الآيبان يُخزَّن على مستوى المستخدم لا الدور.
  Widget _buildBankSection(BuildContext context) {
    return _SectionCard(
      icon: Icons.account_balance_outlined,
      title: context.tr('الحساب البنكي'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: Text(
            context.tr('تُحوَّل عليه مستحقاتك من الحجوزات والجلسات.'),
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
          ),
        ),
        LabeledInput(
          label: '${context.tr('رقم الآيبان (IBAN)')} *',
          hint: 'SA00 0000 0000 0000 0000 0000',
          icon: Icons.tag,
          controller: _ibanCtrl,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
          ],
          onChanged: (v) => _data.bankIban = v,
          validator: _ibanValidator,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: '${context.tr('اسم البنك')} *',
          hint: context.tr('مثال: الراجحي، الأهلي، الإنماء'),
          icon: Icons.account_balance_wallet_outlined,
          controller: _bankNameCtrl,
          onChanged: (v) => _data.bankName = v,
          validator: _requiredValidator,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: '${context.tr('اسم صاحب الحساب')} *',
          hint: context.tr('كما هو مسجّل لدى البنك'),
          icon: Icons.badge_outlined,
          controller: _accountHolderCtrl,
          onChanged: (v) => _data.bankAccountHolder = v,
          validator: _requiredValidator,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  // ── Coach ─────────────────────────────────────────────────────────────────

  List<Widget> _buildCoachSections(BuildContext context) {
    return [
      _SectionCard(
        icon: Icons.emoji_events_outlined,
        title: context.tr('معلومات مهنية'),
        children: [
          LabeledInput(
            label: '${context.tr('الاسم بالإنجليزية')} *',
            hint: context.tr('الاسم الكامل بالإنجليزية'),
            icon: Icons.badge_outlined,
            controller: _coachNameEnCtrl,
            onChanged: (v) => _data.coachNameEn = v,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            '${context.tr('coachSport')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _buildSportPicker(context),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('coachHourlyRate')} *',
            hint: context.tr('coachHourlyRateHint'),
            icon: Icons.payments_outlined,
            controller: _hourlyRateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (v) => _data.coachHourlyRate = v,
            validator: _rateValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: context.tr('coachBio'),
            hint: context.tr('coachBioHint'),
            controller: _coachBioCtrl,
            maxLines: 3,
            onChanged: (v) => _data.coachBio = v,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            '${context.tr('سنوات الخبرة')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _choiceGrid(
            options: _experienceOptions,
            selected: _data.coachExperienceLevel,
            onSelect: (v) => setState(() => _data.coachExperienceLevel = v),
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: context.tr('الشهادات والمؤهلات'),
            hint: context.tr('مثال: مدرب معتمد من الاتحاد السعودي للبادل'),
            controller: _certificationsCtrl,
            maxLines: 3,
            onChanged: (v) => _data.coachCertifications = v,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            '${context.tr('التخصصات')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _buildSpecializationsPicker(context),
        ],
      ),
      const SizedBox(height: AppSizes.xxl),
      _SectionCard(
        icon: Icons.tune_outlined,
        title: context.tr('التفضيلات والأسعار'),
        children: [
          Text(
            '${context.tr('الفئة المستهدفة')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _choiceGrid(
            options: [('male', trg('رجال')), ('female', trg('نساء'))],
            selected: _data.coachTargetGender,
            onSelect: (v) => setState(() => _data.coachTargetGender = v),
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: context.tr('سعر الباقة (8 حصص) (ر.س)'),
            hint: context.tr('مثال: 1000'),
            icon: Icons.card_giftcard_outlined,
            controller: _packagePriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (v) => _data.coachPackagePrice = v,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            context.tr('الملعب الذي تدرب فيه'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _buildVenuePicker(context),
          const SizedBox(height: AppSizes.xl),
          Text(
            '${context.tr('الأيام المتاحة للتدريب')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _dayPicker(context),
        ],
      ),
      const SizedBox(height: AppSizes.xxl),
      _SectionCard(
        icon: Icons.description_outlined,
        title: context.tr('رفع الوثائق'),
        children: [
          Text(
            '${context.tr('الجنسية')} *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _choiceGrid(
            options: [('saudi', trg('سعودي')), ('resident', trg('مقيم'))],
            selected: _data.coachResidency,
            onSelect: (v) => setState(() => _data.coachResidency = v),
          ),
          const SizedBox(height: AppSizes.xl),
          ImageUploadField(
            label:
                '${_data.coachResidency == 'resident' ? context.tr('الإقامة (الوجه الأمامي)') : context.tr('الهوية الوطنية (الوجه الأمامي)')} *',
            value: _data.coachNationalIdFrontUrl,
            onChanged: (url) =>
                setState(() => _data.coachNationalIdFrontUrl = url),
          ),
          const SizedBox(height: AppSizes.xl),
          ImageUploadField(
            label:
                '${_data.coachResidency == 'resident' ? context.tr('الإقامة (الوجه الخلفي)') : context.tr('الهوية الوطنية (الوجه الخلفي)')} *',
            value: _data.coachNationalIdBackUrl,
            onChanged: (url) =>
                setState(() => _data.coachNationalIdBackUrl = url),
          ),
        ],
      ),
    ];
  }

  /// Sports list the coach picks his specialization from. Selecting a sport
  /// stores its id (sent as `sportId`) and mirrors its name into the legacy
  /// free-text specialization field the backend still requires.
  Widget _buildSportPicker(BuildContext context) {
    return FormField<int>(
      validator: (_) =>
          _data.coachSportId == null ? context.tr('fieldRequired') : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<SportEntity>>(
              future: _sportsFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _FieldSkeleton();
                }
                if (snap.hasError || (snap.data?.isEmpty ?? true)) {
                  return _loadError(
                      context, () => setState(() {
                        _sportsFuture = getIt<SportRepository>().fetchSports();
                      }));
                }
                final rtl = Directionality.of(context) == TextDirection.rtl;
                return Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final sport in snap.data!)
                      _chip(
                        label: rtl ? sport.nameAr : sport.nameEn,
                        selected: _data.coachSportId == sport.id,
                        onTap: () {
                          setState(() {
                            _data.coachSportId = sport.id;
                            _data.coachSpecialization =
                                rtl ? sport.nameAr : sport.nameEn;
                          });
                          field.didChange(sport.id);
                        },
                      ),
                  ],
                );
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                field.errorText!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.destructive),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Admin-managed training specializations (checkbox-style rows, ≥1 required).
  Widget _buildSpecializationsPicker(BuildContext context) {
    return FutureBuilder<List<CoachSpecializationEntity>>(
      future: _specializationsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _FieldSkeleton();
        }
        if (snap.hasError || (snap.data?.isEmpty ?? true)) {
          return _loadError(
              context, () => setState(() {
                _specializationsFuture =
                    getIt<CoachRepository>().fetchSpecializations();
              }));
        }
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Column(
          children: [
            for (final spec in snap.data!)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _checkRow(
                  label: rtl ? spec.nameAr : spec.nameEn,
                  selected: _data.coachSpecializationIds.contains(spec.id),
                  onTap: () => setState(() {
                    if (!_data.coachSpecializationIds.remove(spec.id)) {
                      _data.coachSpecializationIds.add(spec.id);
                    }
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Optional picker for the venue the coach usually trains at.
  Widget _buildVenuePicker(BuildContext context) {
    return FutureBuilder<List<VenueOption>>(
      future: _venuesFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _FieldSkeleton();
        }
        if (snap.hasError) {
          return _loadError(
              context, () => setState(() {
                _venuesFuture = getIt<VenueRepository>().fetchOptions();
              }));
        }
        final venues = snap.data ?? const <VenueOption>[];
        if (venues.isEmpty) {
          return Text(context.tr('لا توجد ملاعب متاحة بعد'),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedForeground));
        }
        return DropdownButtonFormField<int>(
          initialValue: _data.coachPreferredVenueId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            hintText: context.tr('اختر الملعب'),
          ),
          items: [
            for (final v in venues)
              DropdownMenuItem(
                  value: v.id, child: Text('${v.name} • ${v.city}')),
          ],
          onChanged: (v) =>
              setState(() => _data.coachPreferredVenueId = v),
        );
      },
    );
  }

  Widget _dayPicker(BuildContext context) {
    return _MultiChoiceGrid(
      options: _dayOptions,
      selected: _data.coachAvailableDays,
      onToggle: (v) => setState(() {
        if (!_data.coachAvailableDays.remove(v)) {
          _data.coachAvailableDays.add(v);
        }
      }),
    );
  }

  Widget _choiceGrid({
    required List<(String value, String label)> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.sm,
      mainAxisSpacing: AppSizes.sm,
      childAspectRatio: 2.6,
      children: [
        for (final (value, label) in options)
          _outlinedChoice(
            label: label,
            selected: selected == value,
            onTap: () => onSelect(value),
          ),
      ],
    );
  }

  Widget _outlinedChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Center(
          child: Text(context.tr(label),
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.secondary,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  Widget _checkRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg, vertical: AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? AppColors.primary : AppColors.secondary,
                  )),
              if (selected)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadError(BuildContext context, VoidCallback onRetry) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr('تعذّر تحميل البيانات'),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(context.tr('إعادة المحاولة')),
        ),
      ],
    );
  }

  // ── Venue ─────────────────────────────────────────────────────────────────

  Widget _buildVenueSection(BuildContext context) {
    // Registration only collects the owner's personal documents. Court data
    // (name, images, location, count) is added later from the owner dashboard.
    return _SectionCard(
      icon: Icons.description_outlined,
      title: context.tr('مستندات الملعب'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: Text(
            context.tr('ارفع مستنداتك، وبعد إنشاء الحساب يمكنك إضافة ملاعبك.'),
            style:
                AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
          ),
        ),
        ImageUploadField(
          label: '${context.tr('صورة السجل التجاري')} *',
          value: _data.venueCommercialRegistrationImageUrl,
          onChanged: (url) =>
              setState(() => _data.venueCommercialRegistrationImageUrl = url),
        ),
        const SizedBox(height: AppSizes.xl),
        ImageUploadField(
          label: '${context.tr('صورة الهوية')} *',
          value: _data.venueOwnerIdImageUrl,
          onChanged: (url) => setState(() => _data.venueOwnerIdImageUrl = url),
        ),
        const SizedBox(height: AppSizes.xl),
        ImageUploadField(
          label: '${context.tr('صورة شهادة الضريبة')} *',
          value: _data.venueTaxCertificateUrl,
          onChanged: (url) =>
              setState(() => _data.venueTaxCertificateUrl = url),
        ),
      ],
    );
  }

  // ── Validators ──────────────────────────────────────────────────────────

  String? _rateValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    final rate = double.tryParse(v.trim());
    if (rate == null || rate <= 0) return context.tr('invalidRate');
    return null;
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('fieldRequired') : null;

  /// آيبان سعودي: SA + رقمَا تحقق + 20 خانة = 24. التحقق الرقمي (mod-97)
  /// يتم في الخادم؛ هنا نتحقق من الشكل فقط.
  String? _ibanValidator(String? v) {
    final iban = (v ?? '').replaceAll(' ', '').toUpperCase();
    if (iban.isEmpty) return context.tr('fieldRequired');
    if (!RegExp(r'^SA\d{22}$').hasMatch(iban)) {
      return context.tr('آيبان غير صحيح — يبدأ بـ SA ويتكوّن من 24 خانة');
    }
    return null;
  }
}

/// A grid of multi-select day chips (used for the coach's available days).
class _MultiChoiceGrid extends StatelessWidget {
  const _MultiChoiceGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<(String value, String label)> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.sm,
      mainAxisSpacing: AppSizes.sm,
      childAspectRatio: 2.6,
      children: [
        for (final (value, label) in options)
          _DayChoice(
            label: label,
            selected: selected.contains(value),
            onTap: () => onToggle(value),
          ),
      ],
    );
  }
}

class _DayChoice extends StatelessWidget {
  const _DayChoice(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Center(
          child: Text(context.tr(label),
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.secondary,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }
}

// ── Section card ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                title,
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          ...children,
        ],
      ),
    );
  }
}

/// مكان قائمة اختيار يُجلب محتواها (رياضات، تخصصات، أندية): حقول متوهجة
/// بدل مؤشر دوّار.
class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Column(
          children: [
            SkeletonBox(height: 48, radius: AppSizes.radiusLg),
            SizedBox(height: AppSizes.sm),
            SkeletonBox(height: 48, radius: AppSizes.radiusLg),
          ],
        ),
      );
}
