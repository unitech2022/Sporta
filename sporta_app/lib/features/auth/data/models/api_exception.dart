import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.messageAr,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? messageAr;
  final String? code;
  final int? statusCode;

  String localized(bool isArabic) =>
      isArabic && messageAr != null ? messageAr! : message;

  factory ApiException.fromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message']?.toString() ?? 'Unknown error',
        messageAr: data['messageAr']?.toString(),
        code: data['code']?.toString(),
        statusCode: response.statusCode,
      );
    }
    return ApiException(
      message: 'Server error',
      messageAr: 'خطأ في الخادم',
      statusCode: response.statusCode,
    );
  }

  static const network = ApiException(
    message: 'Could not connect to server',
    messageAr: 'تعذر الاتصال بالخادم',
    code: 'NETWORK_ERROR',
  );

  static const unexpected = ApiException(
    message: 'An unexpected error occurred',
    messageAr: 'حدث خطأ غير متوقع',
    code: 'UNEXPECTED',
  );
}
