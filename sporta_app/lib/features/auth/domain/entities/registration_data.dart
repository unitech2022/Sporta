import '../../../../core/state/app_settings.dart';

class RegistrationData {
  RegistrationData();

  String firstName = '';
  String lastName = '';
  String phone = '';

  /// التذكرة الصادرة من `/auth/otp/verify` بغرض `register` — تُثبت أن صاحب
  /// الطلب يملك الرقم. لا تسجيل بدونها منذ التحوّل إلى الدخول برمز واتساب.
  String verificationToken = '';

  String country = 'السعودية';
  String city = '';
  String district = '';

  /// IDs of the city/district chosen from the managed lists (null if not
  /// chosen). The [city]/[district] strings hold their display names.
  int? cityId;
  int? districtId;

  String gender = '';

  /// Local file path of a chosen profile photo, uploaded after registration.
  String? avatarPath;

  /// موقع المستخدم (لعرض المباريات/الملاعب الأقرب) — إلزامي في خطوة البيانات
  /// الأساسية، ويُقرأ من GPS الجهاز لا بتقريب يدوي على الخريطة.
  double? latitude;
  double? longitude;

  final Set<UserRole> roles = {};

  // Coach role details (collected when [UserRole.coach] is selected).
  String coachBio = '';

  /// اسم المدرب بالإنجليزية — إلزامي عند التسجيل كمدرب.
  String coachNameEn = '';
  String coachSpecialization = '';
  String coachHourlyRate = '';

  /// Id of the sport the coach specializes in, picked from the sports list.
  int? coachSportId;

  /// الشهادات والمؤهلات — اختياري.
  String coachCertifications = '';

  /// سنوات الخبرة — "lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".
  String? coachExperienceLevel;

  /// معرّفات التخصصات التدريبية المختارة (من `/coach-specializations`).
  final Set<int> coachSpecializationIds = {};

  /// الفئة المستهدفة بالتدريب — "male" | "female".
  String? coachTargetGender;

  /// سعر باقة 8 حصص (ر.س) — اختياري.
  String coachPackagePrice = '';

  /// الملعب الذي يدرب فيه (من `/venues/options`) — اختياري.
  int? coachPreferredVenueId;

  /// الأيام المتاحة للتدريب — مفاتيح مثل "sat","sun".
  final Set<String> coachAvailableDays = {};

  /// الجنسية — "saudi" | "resident".
  String? coachResidency;

  /// روابط صور الهوية الوطنية/الإقامة (مرفوعة عبر /api/uploads/image).
  String? coachNationalIdFrontUrl;
  String? coachNationalIdBackUrl;

  // الحساب البنكي لاستلام المستحقات — مطلوب لدوري المدرب والملعب.
  String bankIban = '';
  String bankName = '';
  String bankAccountHolder = '';

  // Venue role details (collected when [UserRole.venue] is selected).
  String venueName = '';
  String venueDescription = '';
  String venueAddress = '';
  String venueCity = '';
  String venueDistrict = '';
  int? venueCityId;
  int? venueDistrictId;
  String venueGenderPolicy = 'men';

  /// Venue location picked on the map.
  double? venueLatitude;
  double? venueLongitude;

  /// Venue-owner personal documents (required for the venue role). Uploaded
  /// file URLs (`/uploads/...`) returned by the upload endpoint. Court data is
  /// added later from the owner dashboard, not at registration.
  String? venueCommercialRegistrationImageUrl;
  String? venueOwnerIdImageUrl;
  String? venueTaxCertificateUrl;

  /// Whether the owner's required documents (registration, ID, tax) are set.
  bool get hasVenueDetails =>
      (venueCommercialRegistrationImageUrl?.isNotEmpty ?? false) &&
      (venueOwnerIdImageUrl?.isNotEmpty ?? false) &&
      (venueTaxCertificateUrl?.isNotEmpty ?? false);

  bool get hasBasicInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      phone.isNotEmpty &&
      verificationToken.isNotEmpty &&
      gender.isNotEmpty &&
      city.isNotEmpty &&
      latitude != null &&
      longitude != null;

  bool get needsCoachDetails => roles.contains(UserRole.coach);
  bool get needsVenueDetails => roles.contains(UserRole.venue);

  /// Whether an extra step is required to collect coach/venue details.
  bool get needsRoleDetails => needsCoachDetails || needsVenueDetails;
}
