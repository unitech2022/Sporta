import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../locations/presentation/city_district_selector.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// Edit personal info (name / city / district) wired to the backend.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;

  // Selected city/district (from the managed lists).
  int? _cityId;
  int? _districtId;
  String _cityName = '';
  String _districtName = '';

  bool _saving = false;
  bool _uploadingAvatar = false;

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingAvatar = true);
    final error = await context.auth.uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('تم تحديث الصورة'))),
    );
  }

  @override
  void initState() {
    super.initState();
    final user = context.auth.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _cityId = user?.cityId;
    _districtId = user?.districtId;
    _cityName = user?.city ?? '';
    _districtName = user?.district ?? '';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final error = await context.auth.updateProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      city: _cityName,
      district: _districtName,
      cityId: _cityId,
      districtId: _districtId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('تم حفظ التعديلات'))),
    );
    if (error == null) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: context
                    .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _avatar()),
                      const SizedBox(height: AppSizes.xl),
                      _field(context.tr('الاسم الأول'), _firstName, required: true),
                      const SizedBox(height: AppSizes.lg),
                      _field(context.tr('الاسم الأخير'), _lastName, required: true),
                      const SizedBox(height: AppSizes.lg),
                      CityDistrictSelector(
                        initialCityId: _cityId,
                        initialDistrictId: _districtId,
                        required: false,
                        onChanged: (city, district) {
                          final rtl =
                              Directionality.of(context) == TextDirection.rtl;
                          _cityId = city?.id;
                          _cityName = city == null
                              ? ''
                              : (rtl ? city.nameAr : city.nameEn);
                          _districtId = district?.id;
                          _districtName = district == null
                              ? ''
                              : (rtl ? district.nameAr : district.nameEn);
                        },
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(context.tr('حفظ')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(context.tr('تعديل الملف الشخصي'),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final url = context.auth.user?.avatarUrl;
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        children: [
          NetworkCircleAvatar(
            imageUrl: url,
            radius: 48,
            backgroundColor: const Color(0xFFE5E7EB),
            child: const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
          ),
          if (_uploadingAvatar)
            const Positioned.fill(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.black26,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary)),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: c,
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('هذا الحقل مطلوب') : null
              : null,
        ),
      ],
    );
  }
}
