import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/image_upload_field.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../sports/data/sport_models.dart';
import '../../../sports/data/sport_repository.dart';
import '../../../venue/data/venue_repository.dart';
import '../../../venue/domain/entities/owner_venue.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_specialization_entity.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// Shows and lets the signed-in coach edit every field of their profile:
/// name/city, professional info (sport, rate, bio, experience,
/// certifications, specializations), preferences (target gender, package
/// price, preferred venue, available days) and identity documents.
class CoachProfileEditPage extends StatefulWidget {
  const CoachProfileEditPage({super.key});

  @override
  State<CoachProfileEditPage> createState() => _CoachProfileEditPageState();
}

class _CoachProfileEditPageState extends State<CoachProfileEditPage> {
  final _repo = getIt<CoachRepository>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _city;
  final _bio = TextEditingController();
  final _certifications = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _packagePrice = TextEditingController();

  late Future<List<SportEntity>> _sportsFuture = getIt<SportRepository>()
      .fetchSports();
  late Future<List<CoachSpecializationEntity>> _specializationsFuture =
      getIt<CoachRepository>().fetchSpecializations();
  late Future<List<VenueOption>> _venuesFuture = getIt<VenueRepository>()
      .fetchOptions();

  int? _sportId;
  String? _specialization;
  String? _experienceLevel;
  String? _targetGender;
  String? _residency;
  int? _preferredVenueId;
  String? _preferredVenueName;
  final Set<String> _availableDays = {};
  final Set<int> _specializationIds = {};
  String? _nationalIdFrontUrl;
  String? _nationalIdBackUrl;

  // Read-only, computed by the backend from actual bookings/ratings.
  double _rating = 0;
  int _reviews = 0;
  int _students = 0;
  bool _isVerified = false;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingAvatar = true);
    final error = await context.auth.uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('تم تحديث الصورة'))),
    );
  }

  Widget _avatarPicker() {
    final url = context.auth.user?.avatarUrl;
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            NetworkCircleAvatar(
              imageUrl: url,
              radius: 48,
              backgroundColor: const Color(0xFFE5E7EB),
              child: const Icon(
                Icons.person,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
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
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  void initState() {
    super.initState();
    final user = context.auth.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _city = TextEditingController(text: user?.city ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final coach = await _repo.fetchMyCoachProfile();
      if (!mounted) return;
      setState(() {
        _firstName.text = coach.firstName;
        _lastName.text = coach.lastName;
        _city.text = coach.city ?? '';
        _bio.text = coach.bio ?? '';
        _certifications.text = coach.certifications ?? '';
        _hourlyRate.text = coach.hourlyRate > 0
            ? coach.hourlyRate.toString()
            : '';
        _packagePrice.text =
            coach.packagePrice != null && coach.packagePrice! > 0
            ? coach.packagePrice.toString()
            : '';
        _sportId = coach.sportId;
        _specialization = coach.specialization;
        _experienceLevel = coach.experienceLevel;
        _targetGender = coach.targetGender;
        _residency = coach.residency;
        _preferredVenueId = coach.preferredVenueId;
        _preferredVenueName = coach.preferredVenueName;
        _availableDays
          ..clear()
          ..addAll(coach.availableDays);
        _specializationIds
          ..clear()
          ..addAll(coach.specializationIds);
        _nationalIdFrontUrl = coach.nationalIdFrontUrl;
        _nationalIdBackUrl = coach.nationalIdBackUrl;
        _rating = coach.rating;
        _reviews = coach.reviews;
        _students = coach.students;
        _isVerified = coach.isVerified;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _city.dispose();
    _bio.dispose();
    _certifications.dispose();
    _hourlyRate.dispose();
    _packagePrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final formOk = _formKey.currentState?.validate() ?? false;
    String? missing;
    if (_sportId == null) {
      missing = context.tr('يرجى اختيار اللعبة');
    } else if (_experienceLevel == null) {
      missing = context.tr('يرجى اختيار سنوات الخبرة');
    } else if (_specializationIds.isEmpty) {
      missing = context.tr('يرجى اختيار تخصص واحد على الأقل');
    } else if (_targetGender == null) {
      missing = context.tr('يرجى اختيار الفئة المستهدفة');
    } else if (_availableDays.isEmpty) {
      missing = context.tr('يرجى اختيار الأيام المتاحة للتدريب');
    } else if (_residency == null) {
      missing = context.tr('يرجى اختيار الجنسية');
    } else if (_nationalIdFrontUrl?.isEmpty ?? true) {
      missing = context.tr('يرجى رفع صورة الهوية (الوجه الأمامي)');
    } else if (_nationalIdBackUrl?.isEmpty ?? true) {
      missing = context.tr('يرجى رفع صورة الهوية (الوجه الخلفي)');
    }
    if (!formOk || missing != null) {
      if (missing != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(missing)));
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final auth = context.auth;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateMyCoachProfile(
        bio: _bio.text.trim(),
        specialization: _specialization?.trim(),
        sportId: _sportId,
        hourlyRate: double.tryParse(_hourlyRate.text.trim()),
        certifications: _certifications.text.trim(),
        experienceLevel: _experienceLevel,
        targetGender: _targetGender,
        packagePrice: double.tryParse(_packagePrice.text.trim()),
        preferredVenueId: _preferredVenueId ?? 0,
        availableDays: _availableDays.toList(),
        residency: _residency,
        nationalIdFrontUrl: _nationalIdFrontUrl,
        nationalIdBackUrl: _nationalIdBackUrl,
        specializationIds: _specializationIds.toList(),
      );
      // Name / city via the shared profile endpoint (keeps the cached user in sync).
      final err = await auth.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        city: _city.text.trim(),
      );
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _saving = false;
          _error = err;
        });
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم حفظ الملف الشخصي'))),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.display;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('تعديل الملف الشخصي')),
        ),
        body: _loading
            ? const BrandedLoader()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: context.safeBottom(
                    const EdgeInsets.all(AppSizes.pagePadding),
                  ),
                  children: [
                    _statsCard(context),
                    const SizedBox(height: AppSizes.xxl),
                    _SectionCard(
                      icon: Icons.person_outline,
                      title: context.tr('البيانات الشخصية'),
                      children: [
                        _avatarPicker(),
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _firstName,
                                context.tr('الاسم الأول'),
                                required: true,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: _field(
                                _lastName,
                                context.tr('اسم العائلة'),
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _field(_city, context.tr('المدينة')),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    _SectionCard(
                      icon: Icons.emoji_events_outlined,
                      title: context.tr('معلومات مهنية'),
                      children: [
                        Text(
                          '${context.tr('coachSport')} *',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _buildSportPicker(context),
                        const SizedBox(height: AppSizes.xl),
                        _field(
                          _hourlyRate,
                          '${context.tr('سعر الساعة (ر.س)')} *',
                          keyboardType: TextInputType.number,
                          required: true,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _field(_bio, context.tr('نبذة تعريفية'), maxLines: 4),
                        const SizedBox(height: AppSizes.xl),
                        Text(
                          '${context.tr('سنوات الخبرة')} *',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _choiceGrid(
                          options: _experienceOptions,
                          selected: _experienceLevel,
                          onSelect: (v) => setState(() => _experienceLevel = v),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _field(
                          _certifications,
                          context.tr('الشهادات والمؤهلات'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        Text(
                          '${context.tr('التخصصات')} *',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
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
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _choiceGrid(
                          options: [
                            ('male', context.tr('رجال')),
                            ('female', context.tr('نساء')),
                          ],
                          selected: _targetGender,
                          onSelect: (v) => setState(() => _targetGender = v),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _field(
                          _packagePrice,
                          context.tr('سعر الباقة (8 حصص) (ر.س)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        Text(
                          context.tr('الملعب الذي تدرب فيه'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _buildVenuePicker(context),
                        const SizedBox(height: AppSizes.xl),
                        Text(
                          '${context.tr('الأيام المتاحة للتدريب')} *',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _MultiChoiceGrid(
                          options: _dayOptions,
                          selected: _availableDays,
                          onToggle: (v) => setState(() {
                            if (!_availableDays.remove(v)) {
                              _availableDays.add(v);
                            }
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    _SectionCard(
                      icon: Icons.description_outlined,
                      title: context.tr('الوثائق'),
                      children: [
                        Text(
                          '${context.tr('الجنسية')} *',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _choiceGrid(
                          options: [
                            ('saudi', context.tr('سعودي')),
                            ('resident', context.tr('مقيم')),
                          ],
                          selected: _residency,
                          onSelect: (v) => setState(() => _residency = v),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        ImageUploadField(
                          label:
                              '${_residency == 'resident' ? context.tr('الإقامة (الوجه الأمامي)') : context.tr('الهوية الوطنية (الوجه الأمامي)')} *',
                          value: _nationalIdFrontUrl,
                          onChanged: (url) =>
                              setState(() => _nationalIdFrontUrl = url),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        ImageUploadField(
                          label:
                              '${_residency == 'resident' ? context.tr('الإقامة (الوجه الخلفي)') : context.tr('الهوية الوطنية (الوجه الخلفي)')} *',
                          value: _nationalIdBackUrl,
                          onChanged: (url) =>
                              setState(() => _nationalIdBackUrl = url),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        _error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.destructive,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.tr('حفظ')),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Read-only stats computed live by the backend from actual bookings.
  Widget _statsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(
        children: [
          _statItem(context, _rating.toStringAsFixed(1), trg('التقييم')),
          _statDivider(),
          _statItem(context, '$_reviews', trg('التقييمات')),
          _statDivider(),
          _statItem(context, '$_students', trg('الطلاب')),
          if (_isVerified) ...[
            _statDivider(),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.verified, color: Colors.amber, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('معتمد'),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr(label),
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 32, color: Colors.white24);

  /// Sports list the coach picks his specialization from. Selecting a sport
  /// stores its id and mirrors its name into the legacy free-text
  /// specialization field the backend still requires.
  Widget _buildSportPicker(BuildContext context) {
    return FormField<int>(
      initialValue: _sportId,
      validator: (_) => _sportId == null ? context.tr('fieldRequired') : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<SportEntity>>(
              future: _sportsFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError || (snap.data?.isEmpty ?? true)) {
                  return _loadError(
                    context,
                    () => setState(() {
                      _sportsFuture = getIt<SportRepository>().fetchSports();
                    }),
                  );
                }
                final rtl = Directionality.of(context) == TextDirection.rtl;
                return Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final sport in snap.data!)
                      _chip(
                        label: rtl ? sport.nameAr : sport.nameEn,
                        selected: _sportId == sport.id,
                        onTap: () {
                          setState(() {
                            _sportId = sport.id;
                            _specialization = rtl ? sport.nameAr : sport.nameEn;
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
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.destructive,
                ),
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
          return const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || (snap.data?.isEmpty ?? true)) {
          return _loadError(
            context,
            () => setState(() {
              _specializationsFuture = getIt<CoachRepository>()
                  .fetchSpecializations();
            }),
          );
        }
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Column(
          children: [
            for (final spec in snap.data!)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _checkRow(
                  label: rtl ? spec.nameAr : spec.nameEn,
                  selected: _specializationIds.contains(spec.id),
                  onTap: () => setState(() {
                    if (!_specializationIds.remove(spec.id)) {
                      _specializationIds.add(spec.id);
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
          return const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _loadError(
            context,
            () => setState(() {
              _venuesFuture = getIt<VenueRepository>().fetchOptions();
            }),
          );
        }
        var venues = snap.data ?? const <VenueOption>[];
        // Ensure the coach's already-saved venue shows even if it fell out
        // of the (approved-only) options list.
        if (_preferredVenueId != null &&
            !venues.any((v) => v.id == _preferredVenueId) &&
            _preferredVenueName != null) {
          venues = [
            VenueOption(
              id: _preferredVenueId!,
              name: _preferredVenueName!,
              city: '',
            ),
            ...venues,
          ];
        }
        if (venues.isEmpty) {
          return Text(
            context.tr('لا توجد ملاعب متاحة بعد'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          );
        }
        return DropdownButtonFormField<int>(
          initialValue: _preferredVenueId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            hintText: context.tr('اختر الملعب'),
          ),
          items: [
            for (final v in venues)
              DropdownMenuItem(
                value: v.id,
                child: Text(v.city.isEmpty ? v.name : '${v.name} • ${v.city}'),
              ),
          ],
          onChanged: (v) => setState(() => _preferredVenueId = v),
        );
      },
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
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Center(
          child: Text(
            context.tr(label),
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.primary : AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            horizontal: AppSizes.lg,
            vertical: AppSizes.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.secondary,
                ),
              ),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(context.tr('إعادة المحاولة')),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? context.tr('هذا الحقل مطلوب')
                : null
          : null,
    );
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
  const _DayChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Center(
          child: Text(
            context.tr(label),
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.primary : AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

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
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
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
