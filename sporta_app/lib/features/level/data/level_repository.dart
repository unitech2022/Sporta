import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/level_assessment_item.dart';
import '../domain/level_question.dart';

/// Result of a submitted level self-assessment.
class LevelAssessmentResult {
  const LevelAssessmentResult({
    required this.level,
    required this.levelNameAr,
    required this.levelNameEn,
  });

  final int level;
  final String levelNameAr;
  final String levelNameEn;

  factory LevelAssessmentResult.fromJson(Map<String, dynamic> json) =>
      LevelAssessmentResult(
        level: (json['level'] as num?)?.toInt() ?? 1,
        levelNameAr: json['levelNameAr']?.toString() ?? '',
        levelNameEn: json['levelNameEn']?.toString() ?? '',
      );
}

class LevelRepository {
  LevelRepository(this._dio);

  final Dio _dio;

  /// Loads the admin-defined self-assessment questions for a sport.
  Future<List<LevelQuestion>> fetchQuestions(String sport) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.assessmentQuestions,
        queryParameters: {'sport': sport},
      );
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => LevelQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Submits the self-assessment answers (per-question scores) and returns the
  /// computed player level.
  Future<LevelAssessmentResult> submitAssessment({
    required String sport,
    required List<int> answers,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.levelAssessment,
        data: {'sport': sport, 'answers': answers},
      );
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      return LevelAssessmentResult.fromJson(data);
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }

  /// Path 2: uploads a video for assessment (pending coach review).
  Future<LevelAssessmentItem> submitVideo(String filePath) async {
    return _guard(() async {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(ApiEndpoints.levelVideo, data: form);
      return LevelAssessmentItem.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Path 3: requests a level assessment from a coach (by coach-profile id).
  Future<LevelAssessmentItem> requestCoach(int coachId) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.levelCoach,
        data: {'coachId': coachId},
      );
      return LevelAssessmentItem.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<List<LevelAssessmentItem>> fetchMyAssessments() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.myAssessments);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => LevelAssessmentItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> ? (body['data'] ?? body) : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
