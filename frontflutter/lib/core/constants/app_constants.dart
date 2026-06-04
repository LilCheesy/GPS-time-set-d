import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Backend API Configuration
  static String get backendBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (e) {
      // Fallback if Platform check fails
    }
    return 'http://127.0.0.1:8080';
  }
  static const String sosEndpoint = '/api/sos';
  static const String sosScanEndpoint = '/api/sos/scan';

  // TrackAsia/OSRM Routing API
  static const String trackAsiaRouterUrl =
      'http://router.project-osrm.org/route/v1/driving';

  // Default coordinates (Bệnh viện Từ Dũ — fallback location)
  static const double defaultLatitude = 10.7625;
  static const double defaultLongitude = 106.6825;

  // Map configuration
  static const double defaultZoomLevel = 16.0;
  static const int maxZoomLevel = 18;
  static const int minZoomLevel = 3;

  // Location accuracy
  static const double locationAccuracyThreshold = 50.0; // meters

  // Animation durations
  static const Duration mapAnimationDuration = Duration(milliseconds: 500);
  static const Duration iconAnimationDuration = Duration(milliseconds: 300);

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 10);

  // SOS Button dimensions
  static const double sosButtonSize = 80.0;
}
