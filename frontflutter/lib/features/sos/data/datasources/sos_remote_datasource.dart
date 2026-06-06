import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontflutter/core/constants/app_constants.dart';
import 'package:frontflutter/features/sos/data/models/sos_multi_response.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';
import 'package:geolocator/geolocator.dart';

class SosRemoteDatasource {
  final Dio _dio;

  SosRemoteDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: AppConstants.requestTimeout,
              receiveTimeout: AppConstants.requestTimeout,
              sendTimeout: AppConstants.requestTimeout,
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
      throw Exception(_handleDioError(e));
    }
  }

  /// Scan for multiple nearby medical facilities
  Future<SosMultiResponse> scanFacilities(SosRequest request) async {
    // For demo/mobile testing, directly use TrackAsia to avoid 3-second timeout
    // since the local backend (10.0.2.2) is not accessible from the physical phone
    return await _searchTrackAsiaFacilities(request);
  }

  /// Fallback: Use TrackAsia API to find nearby hospitals
  Future<SosMultiResponse> _searchTrackAsiaFacilities(SosRequest request) async {
    try {
      final apiKey = dotenv.env['TRACKASIA_API_KEY'] ?? '';
      final url = 'https://maps.track-asia.com/api/v2/place/nearbysearch/json';
      
      final hospitalFuture = _dio.get(url, queryParameters: {
        'location': '${request.latitude},${request.longitude}',
        'radius': 10000,
        'type': 'hospital',
        'limit': 50,
        'key': apiKey,
      });

      final clinicFuture = _dio.get(url, queryParameters: {
        'location': '${request.latitude},${request.longitude}',
        'radius': 10000,
        'type': 'clinic',
        'limit': 50,
        'key': apiKey,
      });

      final clinicTextFuture = _dio.get(
        'https://maps.track-asia.com/api/v2/place/textsearch/json',
        queryParameters: {
          'location': '${request.latitude},${request.longitude}',
          'radius': 10000,
          'query': 'phòng khám đa khoa', // Be very specific to catch the exact missing clinic
          'limit': 50,
          'key': apiKey,
      });

      final healthStationFuture = _dio.get(
        'https://maps.track-asia.com/api/v2/place/textsearch/json',
        queryParameters: {
          'location': '${request.latitude},${request.longitude}',
          'radius': 10000,
          'query': 'trạm y tế',
          'limit': 50,
          'key': apiKey,
      });

      final exactFuture = _dio.get(
        'https://maps.track-asia.com/api/v2/place/textsearch/json',
        queryParameters: {
          'location': '${request.latitude},${request.longitude}',
          'radius': 10000,
          'query': 'phòng khám',
          'limit': 50,
          'key': apiKey,
      });

      final responses = await Future.wait([
        hospitalFuture, 
        clinicFuture, 
        clinicTextFuture, 
        healthStationFuture,
        exactFuture
      ]);
      
      final List<dynamic> allResults = [];
      final Set<String> seenIds = {}; // Use Set to deduplicate
      
      for (final res in responses) {
        if (res.data['status'] == 'OK' && res.data['results'] != null) {
          for (final item in res.data['results']) {
            final placeId = item['place_id']?.toString() ?? '';
            if (!seenIds.contains(placeId)) {
              seenIds.add(placeId);
              allResults.add(item);
            }
          }
        }
      }

      if (allResults.isNotEmpty) {
        final List<FacilityInfo> facilities = [];
        
        for (final item in allResults) {
          final loc = item['geometry']['location'];
          final destLat = (loc['lat'] as num).toDouble();
          final destLng = (loc['lng'] as num).toDouble();
          
          final distanceMeters = Geolocator.distanceBetween(
            request.latitude, request.longitude,
            destLat, destLng,
          );
          
          facilities.add(FacilityInfo(
            facilityId: item['place_id'].hashCode, // Generate unique numeric ID
            facilityName: item['name'] ?? 'Cơ sở y tế (Từ TrackAsia)',
            facilityAddress: item['formatted_address'] ?? item['vicinity'] ?? 'Không có địa chỉ',
            phone: 'N/A',
            facilityType: 'Bệnh viện',
            destLatitude: destLat,
            destLongitude: destLng,
            distanceMeters: distanceMeters,
            estimatedMinutes: (distanceMeters / 1000 / 30 * 60).ceil(), // Assume 30km/h
          ));
        }
        
        if (facilities.isNotEmpty) {
          // Sort by distance
          facilities.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
          
          return SosMultiResponse(
            status: 'SUCCESS',
            facilities: facilities.take(20).toList(),
            zMetadata: {},
          );
        }
      }
      
      return SosMultiResponse(
        status: 'NO_FACILITY_FOUND',
        facilities: [],
      );
    } catch (e) {
      throw Exception('Lỗi tìm kiếm cơ sở y tế: $e');
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
          'key': apiKey,
        },
      );

      return TrackAsiaRoute.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Handle Dio errors and convert to appropriate error messages
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

