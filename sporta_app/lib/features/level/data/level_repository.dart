import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';

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
  LevelRepository() : _dio = ApiClient.instance.dio;

  final Dio _dio;

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
}
