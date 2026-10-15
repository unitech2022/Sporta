import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/nominatim_service.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/current_location.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../locations/presentation/city_district_selector.dart';
import '../../../venue/presentation/pages/location_picker_page.dart';
import '../../domain/entities/registration_data.dart';
import 'labeled_input.dart';
import '../../../../core/localization/tr_global.dart';

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
  String? _genderError;
  String? _locationError;
  String? _pickedAddress;

  /// قراءة GPS جارية الآن (تلقائياً عند فتح الخطوة أو بضغط "إعادة المحاولة").
  bool _locating = false;

  late final _firstNameCtrl = TextEditingController(text: widget.data.firstName);
  late final _lastNameCtrl = TextEditingController(text: widget.data.lastName);
  late final _phoneCtrl = TextEditingController(text: widget.data.phone);

  @override
  void initState() {
    super.initState();
    // الموقع إلزامي، وأدقّ مصدر له قراءة الجهاز نفسها لا نقطة يقرّبها المستخدم
    // على الخريطة — فنطلبها فور فتح الخطوة ونترك الخريطة للتعديل فقط.
    if (widget.data.latitude == null || widget.data.longitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe());
    } else {
      _resolveAddress(widget.data.latitude!, widget.data.longitude!);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Called by parent before advancing to next step.
  bool validate() {
    final formValid = widget.formKey.currentState?.validate() ?? false;
    final genderValid = widget.data.gender.isNotEmpty;
    final locationValid =
        widget.data.latitude != null && widget.data.longitude != null;
    if (!genderValid) {
      setState(() => _genderError = context.tr('genderRequired'));
    }
    if (!locationValid) {
      setState(() => _locationError = context.tr('locationRequired'));
    }
    return formValid && genderValid && locationValid;
  }

  /// يقرأ إحداثيات الجهاز بأعلى دقة متاحة ويعبّئ بها بيانات التسجيل.
  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final pos = await currentDeviceLocation();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _locating = false;
        _locationError = context.tr('locationUnavailable');
      });
      return;
    }
    widget.data.latitude = pos.latitude;
    widget.data.longitude = pos.longitude;
    setState(() {
      _locating = false;
      _pickedAddress = null;
    });
    _resolveAddress(pos.latitude, pos.longitude);
  }

  /// عنوان مقروء للإحداثيات — للعرض فقط؛ الإحداثيات هي ما يُرسل للخادم.
  Future<void> _resolveAddress(double lat, double lng) async {
    final resolved = await NominatimService().reverse(lat, lng);
    if (!mounted || resolved == null) return;
    setState(() => _pickedAddress = resolved.displayName);
  }

  Future<void> _pickLocation() async {
    final initial = widget.data.latitude != null && widget.data.longitude != null
        ? LatLng(widget.data.latitude!, widget.data.longitude!)
        : null;
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: initial,
          title: context.tr('حدد موقعي على الخريطة'),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      widget.data.latitude = picked.latLng.latitude;
      widget.data.longitude = picked.latLng.longitude;
      _pickedAddress = picked.displayAddress;
      _locationError = null;
    });
  }

  Widget _buildLocationField() {
    final hasLoc = widget.data.latitude != null && widget.data.longitude != null;
    final failed = _locationError != null && !hasLoc;
    final borderColor = failed
        ? AppColors.destructive
        : hasLoc
            ? AppColors.primary
            : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('currentLocation')} *',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_locating)
                    const SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      hasLoc ? Icons.location_on : Icons.location_off_outlined,
                      size: AppSizes.iconMd,
                      color: hasLoc
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _locationStatusText(hasLoc),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              if (hasLoc) ...[
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${widget.data.latitude!.toStringAsFixed(5)}, '
                  '${widget.data.longitude!.toStringAsFixed(5)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ],
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _locating ? null : _locateMe,
                      icon: const Icon(Icons.my_location, size: AppSizes.iconSm),
                      label: Text(
                        context.tr('useMyCurrentLocation'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map_outlined, size: AppSizes.iconSm),
                      label: Text(
                        context.tr('adjustOnMap'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            _locationError!,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.destructive),
          ),
        ],
        const SizedBox(height: AppSizes.xs),
        Text(
          context.tr('locationAccuracyHint'),
          style:
              AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  String _locationStatusText(bool hasLoc) {
    if (_locating) return context.tr('locatingNow');
    if (!hasLoc) return context.tr('locationNotSet');
    return _pickedAddress ?? context.tr('locationCaptured');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان يظهر في هيدر التسجيل — لا حاجة لتكراره هنا.
          Center(child: _AvatarPicker(data: widget.data)),
          const SizedBox(height: AppSizes.xl),
          _sectionHeader(Icons.person_outline, trg('البيانات الشخصية')),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledInput(
                  label: '${context.tr('firstName')} *',
                  hint: context.tr('firstNameHint'),
                  controller: _firstNameCtrl,
                  onChanged: (v) => widget.data.firstName = v,
                  validator: _nameValidator,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: LabeledInput(
                  label: '${context.tr('lastName')} *',
                  hint: context.tr('lastNameHint'),
                  controller: _lastNameCtrl,
                  onChanged: (v) => widget.data.lastName = v,
                  validator: _nameValidator,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _GenderSelector(
            data: widget.data,
            error: _genderError,
            onChanged: () => setState(() => _genderError = null),
          ),
          const SizedBox(height: AppSizes.xl),
          _sectionHeader(Icons.lock_outline, trg('بيانات التواصل والدخول')),
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
          _sectionHeader(Icons.place_outlined, trg('العنوان')),
          CityDistrictSelector(
            initialCityId: widget.data.cityId,
            initialDistrictId: widget.data.districtId,
            onChanged: (city, district) {
              final rtl = Directionality.of(context) == TextDirection.rtl;
              widget.data.cityId = city?.id;
              widget.data.city =
                  city == null ? '' : (rtl ? city.nameAr : city.nameEn);
              widget.data.districtId = district?.id;
              widget.data.district =
                  district == null ? '' : (rtl ? district.nameAr : district.nameEn);
            },
          ),
          const SizedBox(height: AppSizes.md),
          _buildLocationField(),
          const SizedBox(height: AppSizes.xl),
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

  /// عنوان قسم يجمع الحقول المتقاربة بدل قائمة واحدة طويلة.
  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Text(
            context.tr(title),
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(child: Divider()),
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

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    final phoneRx = RegExp(r'^05\d{8}$');
    if (!phoneRx.hasMatch(v.trim())) return context.tr('invalidPhone');
    return null;
  }
}

// ── avatar picker ─────────────────────────────────────────────────────────────

class _AvatarPicker extends StatefulWidget {
  const _AvatarPicker({required this.data});

  final RegistrationData data;

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.data.avatarPath;
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _path = picked.path;
      widget.data.avatarPath = picked.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: _path != null
              ? Image.file(File(_path!), fit: BoxFit.cover)
              : const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: _pick,
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
