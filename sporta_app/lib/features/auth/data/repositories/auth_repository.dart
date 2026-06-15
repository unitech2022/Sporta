import 'package:dio/dio.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/registration_data.dart';
import '../models/api_exception.dart';
import '../models/auth_response.dart';

class AuthRepository {
  AuthRepository() : _dio = ApiClient.instance.dio;

  final Dio _dio;

  Future<AuthResponse> login(String phone, String password) =>
      _post(ApiEndpoints.login, {'phone': phone, 'password': password});

  Future<AuthResponse> register(
    RegistrationData data,
    String language,
  ) =>
      _post(ApiEndpoints.register, {
        'firstName': data.firstName,
        'lastName': data.lastName,
        'email': data.email,
        'phone': data.phone,
        'password': data.password,
        'gender': data.gender,
        'country': data.country,
        'city': data.city,
        if (data.district.isNotEmpty) 'district': data.district,
        'roles': data.roles.map((r) => r.name).toList(),
        'language': language,
        if (data.needsCoachDetails)
          'coach': {
            if (data.coachBio.trim().isNotEmpty) 'bio': data.coachBio.trim(),
            'specialization': data.coachSpecialization.trim(),
            'hourlyRate': double.tryParse(data.coachHourlyRate.trim()) ?? 0,
          },
        if (data.needsVenueDetails)
          'venue': {
            'name': data.venueName.trim(),
            if (data.venueDescription.trim().isNotEmpty)
              'description': data.venueDescription.trim(),
            'city': data.venueCity.trim().isNotEmpty
                ? data.venueCity.trim()
                : data.city,
            'address': data.venueAddress.trim(),
            'genderPolicy': data.venueGenderPolicy,
          },
      });

  Future<AuthResponse> refreshToken(String token) async {
    // Dedicated Dio (no auth interceptor) to avoid loops.
    final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    try {
      final res = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': token},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    }
  }

  Future<void> forgotPassword(String phone) =>
      _postVoid(ApiEndpoints.forgotPassword, {'phone': phone});

  Future<void> verifyOtp(String phone, String otp) =>
      _postVoid(ApiEndpoints.verifyOtp, {'phone': phone, 'otp': otp});

  Future<void> resetPassword(
    String phone,
    String otp,
    String newPassword,
  ) =>
      _postVoid(ApiEndpoints.resetPassword, {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });

  Future<void> updateLanguage(AppLanguage lang) => _putVoid(
        ApiEndpoints.updateLanguage,
        {'language': lang.name},
      );

  Future<void> setFavoriteSport(String sport) =>
      _putVoid(ApiEndpoints.favoriteSport, {'sport': sport});

  // ── helpers ──────────────────────────────────────────────────────────────

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

  Future<void> _postVoid(String path, Map<String, dynamic> body) async {
    try {
      await _dio.post(path, data: body);
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
