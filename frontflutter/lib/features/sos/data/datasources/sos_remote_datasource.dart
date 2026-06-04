import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontflutter/core/constants/app_constants.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';

class SosRemoteDatasource {
  final Dio _dio;

  SosRemoteDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              timeout: AppConstants.requestTimeout,
            ));

  /// Send SOS request to backend
  Future<SosResponse> sendSos(SosRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}${AppConstants.sosEndpoint}',
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return SosResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get route from TrackAsia Routing API
  Future<TrackAsiaRoute> getRoute({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final apiKey = dotenv.env['TRACKASIA_API_KEY'] ?? '';
      final coordinates = '$userLng,$userLat;$destLng,$destLat';

      final response = await _dio.get(
        '${AppConstants.trackAsiaRouterUrl}/$coordinates',
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline6',
          'steps': 'true',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return TrackAsiaRoute.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to appropriate exceptions
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Server not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
