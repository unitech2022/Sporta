import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/utils/phone_input.dart';
import '../../domain/entities/registration_data.dart';
import 'labeled_input.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({
    super.key,
    required this.data,
    required this.formKey,
  });

  final RegistrationData data;
  final GlobalKey<FormState> formKey;

  @override
  State<BasicInfoStep> createState() => BasicInfoStepState();
}

class BasicInfoStepState extends State<BasicInfoStep> {
  bool _showPassword = false;
  String? _genderError;

  late final _firstNameCtrl = TextEditingController(text: widget.data.firstName);
  late final _lastNameCtrl = TextEditingController(text: widget.data.lastName);
  late final _emailCtrl = TextEditingController(text: widget.data.email);
  late final _phoneCtrl = TextEditingController(text: widget.data.phone);
  late final _passwordCtrl = TextEditingController(text: widget.data.password);
  late final _cityCtrl = TextEditingController(text: widget.data.city);
  late final _districtCtrl = TextEditingController(text: widget.data.district);

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  // Called by parent before advancing to next step.
  bool validate() {
    final formValid = widget.formKey.currentState?.validate() ?? false;
    final genderValid = widget.data.gender.isNotEmpty;
    if (!genderValid) {
      setState(() => _genderError = context.tr('genderRequired'));
    }
    return formValid && genderValid;
  }

  /// Fills the form with unique dummy data (development helper). Phone/email
  /// are timestamped so repeated registrations don't collide on the server.
  void autofill() {
    final suffix = DateTime.now().millisecondsSinceEpoch;
    final phone = '05${(suffix % 100000000).toString().padLeft(8, '0')}';
    final email = 'test$suffix@sporta.app';

    _firstNameCtrl.text = 'أحمد';
    _lastNameCtrl.text = 'العتيبي';
    _emailCtrl.text = email;
    _phoneCtrl.text = phone;
    _passwordCtrl.text = 'Test1234';
    _cityCtrl.text = 'الرياض';
    _districtCtrl.text = 'النخيل';

    widget.data
      ..firstName = 'أحمد'
      ..lastName = 'العتيبي'
      ..email = email
      ..phone = phone
      ..password = 'Test1234'
      ..city = 'الرياض'
      ..district = 'النخيل'
      ..gender = 'male';
    if (widget.data.roles.isEmpty) widget.data.roles.add(UserRole.player);

    setState(() {
      _genderError = null;
      _showPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('register'),
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.secondary),
                ),
              ),
              if (kDebugMode)
                OutlinedButton.icon(
                  onPressed: autofill,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                  ),
                  icon: const Icon(Icons.bolt, size: AppSizes.iconSm),
                  label: const Text('ملء تلقائي'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
          const Center(child: _AvatarPicker()),
          const SizedBox(height: AppSizes.xxl),
          LabeledInput(
            label: '${context.tr('firstName')} *',
            hint: context.tr('firstNameHint'),
            controller: _firstNameCtrl,
            onChanged: (v) => widget.data.firstName = v,
            validator: _nameValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('lastName')} *',
            hint: context.tr('lastNameHint'),
            controller: _lastNameCtrl,
            onChanged: (v) => widget.data.lastName = v,
            validator: _nameValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('email')} *',
            hint: 'example@email.com',
            icon: Icons.mail_outline,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => widget.data.email = v,
            validator: _emailValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('phone')} *',
            hint: '05xxxxxxxx',
            icon: Icons.phone_outlined,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: phoneInputFormatters,
            onChanged: (v) => widget.data.phone = v,
            validator: _phoneValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('password')} *',
            hint: '••••••••',
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            onChanged: (v) => widget.data.password = v,
            validator: _passwordValidator,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.mutedForeground,
                size: AppSizes.iconMd,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _GenderSelector(
            data: widget.data,
            error: _genderError,
            onChanged: () => setState(() => _genderError = null),
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: '${context.tr('city')} *',
            hint: context.tr('cityHint'),
            controller: _cityCtrl,
            onChanged: (v) => widget.data.city = v,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? context.tr('cityRequired')
                : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.xl),
          LabeledInput(
            label: context.tr('district'),
            hint: context.tr('districtHint'),
            icon: Icons.location_on_outlined,
            controller: _districtCtrl,
            onChanged: (v) => widget.data.district = v,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSizes.xxl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              context.tr('registerRolesHint'),
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── validators ────────────────────────────────────────────────────────────

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    if (v.trim().length < 2) return context.tr('nameTooShort');
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    final emailRx = RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRx.hasMatch(v.trim())) return context.tr('invalidEmail');
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    final phoneRx = RegExp(r'^05\d{8}$');
    if (!phoneRx.hasMatch(v.trim())) return context.tr('invalidPhone');
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return context.tr('fieldRequired');
    if (v.length < 8) return context.tr('passwordTooShort');
    if (!RegExp(r'[a-zA-Z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return context.tr('passwordWeak');
    }
    return null;
  }
}

// ── avatar picker ─────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Icon(
                  Icons.camera_alt,
                  size: AppSizes.iconSm,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── gender selector ───────────────────────────────────────────────────────────

class _GenderSelector extends StatefulWidget {
  const _GenderSelector({
    required this.data,
    required this.onChanged,
    this.error,
  });

  final RegistrationData data;
  final VoidCallback onChanged;
  final String? error;

  @override
  State<_GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<_GenderSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('gender')} *',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(child: _option('male', context.tr('male'))),
            const SizedBox(width: AppSizes.md),
            Expanded(child: _option('female', context.tr('female'))),
          ],
        ),
        if (widget.error != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            widget.error!,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.destructive),
          ),
        ],
      ],
    );
  }

  Widget _option(String value, String label) {
    final selected = widget.data.gender == value;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => widget.data.gender = value);
          widget.onChanged();
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
