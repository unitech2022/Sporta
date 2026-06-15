import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/registration_data.dart';
import 'labeled_input.dart';

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

  late final _specializationCtrl =
      TextEditingController(text: _data.coachSpecialization);
  late final _hourlyRateCtrl =
      TextEditingController(text: _data.coachHourlyRate);
  late final _coachBioCtrl = TextEditingController(text: _data.coachBio);

  late final _venueNameCtrl = TextEditingController(text: _data.venueName);
  late final _venueAddressCtrl =
      TextEditingController(text: _data.venueAddress);
  late final _venueCityCtrl = TextEditingController(text: _data.venueCity);
  late final _venueDescCtrl =
      TextEditingController(text: _data.venueDescription);

  @override
  void dispose() {
    _specializationCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _coachBioCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _venueCityCtrl.dispose();
    _venueDescCtrl.dispose();
    super.dispose();
  }

  /// Called by the parent before advancing to the next step.
  bool validate() => widget.formKey.currentState?.validate() ?? false;

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
          if (_data.needsCoachDetails) _buildCoachSection(context),
          if (_data.needsCoachDetails && _data.needsVenueDetails)
            const SizedBox(height: AppSizes.xxl),
          if (_data.needsVenueDetails) _buildVenueSection(context),
        ],
      ),
    );
  }

  // ── Coach ─────────────────────────────────────────────────────────────────

  Widget _buildCoachSection(BuildContext context) {
    return _SectionCard(
      icon: Icons.emoji_events_outlined,
      title: context.tr('coachInfo'),
      children: [
        LabeledInput(
          label: '${context.tr('coachSpecialization')} *',
          hint: context.tr('coachSpecializationHint'),
          controller: _specializationCtrl,
          onChanged: (v) => _data.coachSpecialization = v,
          validator: _requiredValidator,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: '${context.tr('coachHourlyRate')} *',
          hint: context.tr('coachHourlyRateHint'),
          icon: Icons.payments_outlined,
          controller: _hourlyRateCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
      ],
    );
  }

  // ── Venue ─────────────────────────────────────────────────────────────────

  Widget _buildVenueSection(BuildContext context) {
    return _SectionCard(
      icon: Icons.stadium_outlined,
      title: context.tr('venueInfo'),
      children: [
        LabeledInput(
          label: '${context.tr('venueName')} *',
          hint: context.tr('venueNameHint'),
          controller: _venueNameCtrl,
          onChanged: (v) => _data.venueName = v,
          validator: _requiredValidator,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: '${context.tr('venueAddress')} *',
          hint: context.tr('venueAddressHint'),
          icon: Icons.location_on_outlined,
          controller: _venueAddressCtrl,
          onChanged: (v) => _data.venueAddress = v,
          validator: _requiredValidator,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: context.tr('venueCity'),
          hint: context.tr('cityHint'),
          controller: _venueCityCtrl,
          onChanged: (v) => _data.venueCity = v,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.xl),
        LabeledInput(
          label: context.tr('venueDescription'),
          hint: context.tr('venueDescriptionHint'),
          controller: _venueDescCtrl,
          maxLines: 3,
          onChanged: (v) => _data.venueDescription = v,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: AppSizes.xl),
        Text(
          context.tr('venueGenderPolicy'),
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        _GenderPolicySelector(
          value: _data.venueGenderPolicy,
          onChanged: (v) => setState(() => _data.venueGenderPolicy = v),
        ),
      ],
    );
  }

  // ── Validators ──────────────────────────────────────────────────────────

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('fieldRequired') : null;

  String? _rateValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    final rate = double.tryParse(v.trim());
    if (rate == null || rate <= 0) return context.tr('invalidRate');
    return null;
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

// ── Gender policy selector ───────────────────────────────────────────────────────

class _GenderPolicySelector extends StatelessWidget {
  const _GenderPolicySelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = {
      'mixed': context.tr('venuePolicyMixed'),
      'womenOnly': context.tr('venuePolicyWomenOnly'),
      'familyOnly': context.tr('venuePolicyFamilyOnly'),
    };
    return Column(
      children: [
        for (final entry in options.entries) ...[
          _option(entry.key, entry.value),
          if (entry.key != options.keys.last)
            const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }

  Widget _option(String key, String label) {
    final selected = value == key;
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(key),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.md,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: AppSizes.iconMd,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
