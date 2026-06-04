import 'package:latlong2/latlong2.dart';
import 'package:polyline/polyline.dart' as polyline_lib;

class PolylineDecoder {
  /// Decode a polyline6 encoded string to a list of LatLng points
  static List<LatLng> decodePolyline(String encodedPolyline) {
    try {
      final decoded = polyline_lib.Polyline.fromEncoded(
        encodedPolyline,
        precision: 6,
      );

      return decoded.coordinates
          .map((coord) => LatLng(coord[0], coord[1]))
          .toList();
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  /// Calculate the closest point on the polyline to the given location
  static int getClosestPointIndex(
    List<LatLng> polylinePoints,
    LatLng currentLocation,
  ) {
    if (polylinePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < polylinePoints.length; i++) {
      final distance = _haversineDistance(
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

  /// Calculate Haversine distance between two points in meters
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

class Math {
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double atan2(double y, double x) => math.atan2(y, x);
  static double sqrt(double x) => math.sqrt(x);
}

import 'dart:math' as math;
