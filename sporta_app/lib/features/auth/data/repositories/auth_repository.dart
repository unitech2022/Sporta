import 'package:dio/dio.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/registration_data.dart';
import '../models/api_exception.dart';
import '../models/auth_response.dart';
import '../models/otp_models.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// يطلب رمز تحقق على واتساب لغرض محدّد، ويُرجِع تفاصيل الإرسال.
  Future<OtpRequested> requestOtp(String phone, OtpPurpose purpose) async {
    try {
      final res = await _dio.post(ApiEndpoints.requestOtp, data: {
        'phone': phone,
        'purpose': purpose.wire,
      });
      final body = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return OtpRequested.fromJson(body);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// الدخول اليومي من جهاز موثوق: الرقم + سرّ الجهاز — بلا رمز.
  Future<AuthResponse> loginWithDevice(
    String phone,
    String deviceId,
    String deviceSecret,
  ) =>
      _post(ApiEndpoints.deviceLogin, {
        'phone': phone,
        'deviceId': deviceId,
        'deviceSecret': deviceSecret,
      });

  /// يسجّل هذا الهاتف جهازاً موثوقاً ويُرجِع (المعرّف، السرّ). السرّ يُسلَّم
  /// مرة واحدة فقط — الخادم يحفظ تجزئته لا هو.
  Future<(String deviceId, String secret)> enrollDevice({
    required String deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.enrollDevice, data: {
        'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
        if (platform != null) 'platform': platform,
      });
      final body = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return (body['deviceId'] as String, body['deviceSecret'] as String);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// دخول برمز واتساب — للهاتف غير الموثوق قبل أن يسجّل بصمته.
  Future<AuthResponse> loginWithOtp(String phone, String otp) =>
      _post(ApiEndpoints.otpLogin, {'phone': phone, 'otp': otp});

  /// يُبدّل الرمز بتذكرة تُقدَّم للخطوة التالية (إكمال التسجيل، تأكيد الحذف).
  Future<String> verifyOtpForPurpose(
    String phone,
    String otp,
    OtpPurpose purpose,
  ) async {
    try {
      final res = await _dio.post(ApiEndpoints.otpVerify, data: {
        'phone': phone,
        'otp': otp,
        'purpose': purpose.wire,
      });
      final body = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return body['verificationToken'] as String;
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  Future<AuthResponse> register(
    RegistrationData data,
    String language,
  ) =>
      _post(ApiEndpoints.register, {
        'firstName': data.firstName,
        'lastName': data.lastName,
        'phone': data.phone,
        'verificationToken': data.verificationToken,
        'gender': data.gender,
        'country': data.country,
        'city': data.city,
        if (data.district.isNotEmpty) 'district': data.district,
        if (data.cityId != null) 'cityId': data.cityId,
        if (data.districtId != null) 'districtId': data.districtId,
        if (data.latitude != null) 'latitude': data.latitude,
        if (data.longitude != null) 'longitude': data.longitude,
        'roles': data.roles.map((r) => r.name).toList(),
        'language': language,
        if (data.needsCoachDetails) 'coach': _coachPayload(data),
        // Venue owner: only the owner's personal documents are collected at
        // registration; courts are created later from the owner dashboard.
        if (data.needsVenueDetails) 'venue': _venuePayload(data),
      });

  /// يجدّد الجلسة ويحفظ الزوج الجديد **قبل** قراءة المستخدم: الخادم دوّر
  /// التوكن، فلو فشلت قراءة المستخدم بعد ضياع الزوج الجديد لسقطت الجلسة.
  Future<AuthResponse> refreshToken(String token) async {
    // Dedicated Dio (no auth interceptor) to avoid loops. Same timeouts as the
    // main client so a bad network can't hold the splash screen indefinitely.
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    try {
      final res = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': token},
      );
      final json = res.data as Map<String, dynamic>;
      final data = (json['data'] ?? json) as Map<String, dynamic>;
      final access = data['accessToken']?.toString() ?? '';
      final refresh = data['refreshToken']?.toString() ?? '';
      if (access.isNotEmpty && refresh.isNotEmpty) {
        await SecureStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
          rememberMe: true,
        );
      }
      return AuthResponse.fromJson(json);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    }
  }

  Future<void> updateLanguage(AppLanguage lang) => _putVoid(
        ApiEndpoints.updateLanguage,
        {'language': lang.name},
      );

  Future<void> setFavoriteSport(String sport) =>
      _putVoid(ApiEndpoints.favoriteSport, {'sport': sport});

  /// Updates the user's profile and returns the refreshed user.
  /// Saves/updates the user's location; returns the updated user.
  Future<UserModel> updateLocation(double latitude, double longitude) async {
    try {
      final res = await _dio.put(ApiEndpoints.userLocation, data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      final body = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// Adds a role (+ its details) to the current user; returns the updated user.
  Future<UserModel> addRole(RegistrationData data) async {
    try {
      final role = data.roles.first.name;
      final res = await _dio.post(ApiEndpoints.addRole, data: {
        'role': role,
        if (data.needsCoachDetails) 'coach': _coachPayload(data),
        // Venue owner: only the owner's personal documents at registration.
        if (data.needsVenueDetails) 'venue': _venuePayload(data),
      });
      final body = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// يحذف دوراً من الحساب حذفاً ناعماً. الردّ جلسة جديدة: التوكن القديم يحمل
  /// الدور المحذوف في مطالباته، فيُستبدل فوراً.
  Future<AuthResponse> deleteRole(String role) async {
    try {
      final res = await _dio.delete(ApiEndpoints.deleteRole(role));
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    String? gender,
    String? city,
    String? district,
    int? cityId,
    int? districtId,
  }) async {
    try {
      final res = await _dio.put(ApiEndpoints.updateProfile, data: {
        'firstName': firstName,
        'lastName': lastName,
        if (gender != null) 'gender': gender,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (cityId != null) 'cityId': cityId,
        if (districtId != null) 'districtId': districtId,
      });
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// يحذف الحساب نهائياً بعد تأكيده برمز واتساب. النجاح يعني أن الجلسة على
  /// الخادم انتهت، فيجب على المستدعي مسح التوكنات محلياً فوراً.
  Future<void> deleteAccount(String verificationToken, {String? reason}) async {
    try {
      await _dio.delete(ApiEndpoints.deleteAccount, data: {
        'verificationToken': verificationToken,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// Uploads an avatar image and returns the refreshed user.
  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(ApiEndpoints.uploadAvatar, data: form);
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _coachPayload(RegistrationData data) => {
        if (data.coachBio.trim().isNotEmpty) 'bio': data.coachBio.trim(),
        if (data.coachNameEn.trim().isNotEmpty)
          'nameEn': data.coachNameEn.trim(),
        'specialization': data.coachSpecialization.trim(),
        if (data.coachSportId != null) 'sportId': data.coachSportId,
        'hourlyRate': double.tryParse(data.coachHourlyRate.trim()) ?? 0,
        if (data.coachCertifications.trim().isNotEmpty)
          'certifications': data.coachCertifications.trim(),
        'experienceLevel': data.coachExperienceLevel ?? '',
        'specializationIds': data.coachSpecializationIds.toList(),
        'targetGender': data.coachTargetGender ?? '',
        if (data.coachPackagePrice.trim().isNotEmpty)
          'packagePrice': double.tryParse(data.coachPackagePrice.trim()),
        if (data.coachPreferredVenueId != null)
          'preferredVenueId': data.coachPreferredVenueId,
        'availableDays': data.coachAvailableDays.toList(),
        'residency': data.coachResidency ?? '',
        'nationalIdFrontUrl': data.coachNationalIdFrontUrl ?? '',
        'nationalIdBackUrl': data.coachNationalIdBackUrl ?? '',
        ..._bankPayload(data),
      };

  Map<String, dynamic> _venuePayload(RegistrationData data) => {
        'commercialRegistrationImageUrl':
            data.venueCommercialRegistrationImageUrl ?? '',
        'ownerIdImageUrl': data.venueOwnerIdImageUrl ?? '',
        'taxCertificateUrl': data.venueTaxCertificateUrl ?? '',
        ..._bankPayload(data),
      };

  /// الحساب البنكي لاستلام المستحقات — الآيبان يُرسل بلا مسافات وبأحرف كبيرة.
  Map<String, dynamic> _bankPayload(RegistrationData data) => {
        'iban': data.bankIban.replaceAll(' ', '').toUpperCase(),
        'bankName': data.bankName.trim(),
        'accountHolderName': data.bankAccountHolder.trim(),
      };

  Future<AuthResponse> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  Future<void> _putVoid(String path, Map<String, dynamic> body) async {
    try {
      await _dio.put(path, data: body);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
