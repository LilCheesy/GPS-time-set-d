import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider {
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      // MissingPluginException on Linux Desktop or unsupported environments
      print('Location permission check failed (likely unsupported platform): $e');
      return false;
    }
  }

  static Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get high-accuracy location with fresh GPS fix (no cache).
  /// Falls back to regular accuracy if best accuracy times out.
  static Future<LatLng?> getHighAccuracyLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      try {
        // Try best accuracy first (5 second timeout)
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        ).timeout(
          const Duration(seconds: 5),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (_) {
        // Fallback to high accuracy
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting high accuracy location: $e');
      return null;
    }
  }

  static Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }
}

