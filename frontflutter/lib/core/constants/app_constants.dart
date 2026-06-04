class AppConstants {
  // Backend API Configuration
  static const String backendBaseUrl = 'http://10.0.2.2:8080';
  static const String sosEndpoint = '/api/sos';
  static const String sosScanEndpoint = '/api/sos/scan';

  // TrackAsia Routing API
  static const String trackAsiaRouterUrl =
      'https://router.track-asia.com/v1/route/v1/driving';

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
