import 'package:dio/dio.dart';
import '../../../../core/localization/tr_global.dart';

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

  /// الرسالة بلغة التطبيق الحالية — الاستخدام الافتراضي في الواجهة.
  String get display => localized(isAppArabic);

  factory ApiException.fromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return ApiException(
          message: message,
          messageAr: data['messageAr']?.toString(),
          code: data['code']?.toString(),
          statusCode: response.statusCode,
        );
      }

      // ردّ التحقق الافتراضي من ASP.NET (ValidationProblemDetails) لا يحمل
      // "message"، فكان يظهر للمستخدم كـ "Unknown error". نقرأ منه الحقول
      // المرفوضة حتى تُقال المشكلة بصراحة بدل رسالة عمياء.
      final validation = _validationErrors(data);
      if (validation != null) {
        return ApiException(
          message: 'Invalid request data (${validation.details})',
          messageAr: 'بيانات الطلب غير صالحة: ${validation.fields}',
          code: 'VALIDATION_ERROR',
          statusCode: response.statusCode,
        );
      }

      final title = data['title']?.toString();
      if (title != null && title.isNotEmpty) {
        return ApiException(
          message: title,
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
    return ApiException(
      message: 'Server error',
      messageAr: 'خطأ في الخادم',
      statusCode: response.statusCode,
    );
  }

  /// يستخرج أسماء الحقول ورسائلها من `errors` في ValidationProblemDetails.
  static ({String fields, String details})? _validationErrors(
    Map<String, dynamic> data,
  ) {
    final errors = data['errors'];
    if (errors is! Map || errors.isEmpty) return null;

    final fields = <String>[];
    final details = <String>[];
    errors.forEach((key, value) {
      final name = key.toString();
      fields.add(name);
      final messages = value is List
          ? value.map((e) => e.toString()).join(' ')
          : value.toString();
      details.add('$name: $messages');
    });
    return (fields: fields.join('، '), details: details.join(' | '));
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
