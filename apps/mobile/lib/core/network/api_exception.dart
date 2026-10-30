import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  tooManyRequests,
  server,
  unknown,
}

/// Normalised API failure built from an RFC 9457 `application/problem+json`
/// response (or a transport error).
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    this.statusCode,
    this.title,
    this.detail,
    this.fieldErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiException(kind: ApiErrorKind.network);
    }
    final status = response.statusCode ?? 0;
    String? title;
    String? detail;
    final fieldErrors = <String, List<String>>{};
    final data = response.data;
    if (data is Map) {
      title = data['title'] as String?;
      detail = data['detail'] as String?;
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          // ASP.NET keys are PascalCase ("Title"); normalise to camelCase.
          final k = key.toString();
          final normalised = k.isEmpty ? k : k[0].toLowerCase() + k.substring(1);
          fieldErrors[normalised] = value is List
              ? value.map((e) => e.toString()).toList()
              : [value.toString()];
        });
      }
    }
    return ApiException(
      kind: _kindFor(status),
      statusCode: status,
      title: title,
      detail: detail,
      fieldErrors: fieldErrors,
    );
  }

  static ApiErrorKind _kindFor(int status) => switch (status) {
        400 => ApiErrorKind.validation,
        401 => ApiErrorKind.unauthorized,
        403 => ApiErrorKind.forbidden,
        404 => ApiErrorKind.notFound,
        409 => ApiErrorKind.conflict,
        429 => ApiErrorKind.tooManyRequests,
        >= 500 => ApiErrorKind.server,
        _ => ApiErrorKind.unknown,
      };

  final ApiErrorKind kind;
  final int? statusCode;
  final String? title;
  final String? detail;

  /// Validation errors keyed by camelCase property name.
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => 'ApiException($kind, $statusCode, $title)';
}

/// Runs [call] and converts transport failures to [ApiException].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final inner = e.error;
    if (inner is ApiException) throw inner;
    throw ApiException.fromDio(e);
  }
}
