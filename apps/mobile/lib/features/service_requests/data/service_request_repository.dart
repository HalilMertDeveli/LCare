import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'service_request_models.dart';

abstract class ServiceRequestRepository {
  Future<PagedResult<ServiceRequestSummary>> list({
    ServiceRequestStatus? status,
    int page = 1,
    int pageSize = 50,
  });

  Future<ServiceRequestDetail> get(String id);

  Future<ServiceRequestDetail> create({
    required String title,
    required String description,
  });

  Future<ServiceRequestDetail> changeStatus({
    required String id,
    required ServiceRequestStatus status,
    required int version,
    String? note,
  });
}

class ApiServiceRequestRepository implements ServiceRequestRepository {
  ApiServiceRequestRepository(this._dio);

  final Dio _dio;

  @override
  Future<PagedResult<ServiceRequestSummary>> list({
    ServiceRequestStatus? status,
    int page = 1,
    int pageSize = 50,
  }) =>
      guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/service-requests',
          queryParameters: {
            'status': ?status?.apiValue,
            'page': page,
            'pageSize': pageSize,
          },
        );
        return PagedResult.fromJson(
          response.data!,
          ServiceRequestSummary.fromJson,
        );
      });

  @override
  Future<ServiceRequestDetail> get(String id) => guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/service-requests/${Uri.encodeComponent(id)}',
        );
        return ServiceRequestDetail.fromJson(response.data!);
      });

  @override
  Future<ServiceRequestDetail> create({
    required String title,
    required String description,
  }) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/service-requests',
          data: {'title': title, 'description': description},
        );
        return ServiceRequestDetail.fromJson(response.data!);
      });

  @override
  Future<ServiceRequestDetail> changeStatus({
    required String id,
    required ServiceRequestStatus status,
    required int version,
    String? note,
  }) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/service-requests/${Uri.encodeComponent(id)}/status',
          data: {
            'status': status.apiValue,
            'version': version,
            // `note` is optional in ChangeStatusRequest: omit when empty.
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          },
        );
        return ServiceRequestDetail.fromJson(response.data!);
      });
}
