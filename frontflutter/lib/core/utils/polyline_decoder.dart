import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Decodes polyline-encoded strings (precision 5 or 6) into coordinates.
/// This replaces the removed 'polyline' package with a manual implementation.
class PolylineDecoder {
  /// Decode a polyline-encoded string to a list of LatLng points.
  ///
  /// [encodedPolyline] - The encoded polyline string from the routing API.
  /// [precision] - 5 for Google-style, 6 for OSRM/TrackAsia-style (polyline6).
  static List<LatLng> decodePolyline(String encodedPolyline, {int precision = 6}) {
    try {
      final List<LatLng> points = [];
      final int factor = math.pow(10, precision).toInt();
      int index = 0;
      int lat = 0;
      int lng = 0;

      while (index < encodedPolyline.length) {
        // Decode latitude
        int shift = 0;
        int result = 0;
        int byte;
        do {
          byte = encodedPolyline.codeUnitAt(index++) - 63;
          result |= (byte & 0x1F) << shift;
          shift += 5;
        } while (byte >= 0x20);
        int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lat += dlat;

        // Decode longitude
        shift = 0;
        result = 0;
        do {
          byte = encodedPolyline.codeUnitAt(index++) - 63;
          result |= (byte & 0x1F) << shift;
          shift += 5;
        } while (byte >= 0x20);
        int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
        lng += dlng;

        points.add(LatLng(lat / factor, lng / factor));
      }

      return points;
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  /// Calculate the closest point index on the polyline to the given location
  static int getClosestPointIndex(
    List<LatLng> polylinePoints,
    LatLng currentLocation,
  ) {
    if (polylinePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < polylinePoints.length; i++) {
      final distance = haversineDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        polylinePoints[i].latitude,
        polylinePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Calculate Haversine distance between two points in meters.
  /// Made public so it can be reused across the app.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
