import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class LocationProvider {
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service is disabled.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Requested permission status: $permission');
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission is denied forever.');
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      // MissingPluginException on Linux Desktop or unsupported environments
      print('Location permission check failed: $e');
      return false;
    }
  }

  static Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Quick fallback: try to get last known position for fast initial load
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return LatLng(lastPosition.latitude, lastPosition.longitude);
        }
      } catch (_) {}

      // If no last position, wait for current position with a longer timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get high-accuracy location with fresh GPS fix (no cache).
  /// On web, uses high accuracy directly (best is not supported).
  /// Falls back quickly to avoid blocking the SOS flow.
  static Future<LatLng?> getHighAccuracyLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // On web, LocationAccuracy.best often fails. Use high directly.
      final accuracy = kIsWeb ? LocationAccuracy.high : LocationAccuracy.best;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
        ).timeout(
          const Duration(seconds: 3),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (_) {
        // Quick fallback: try medium accuracy with short timeout
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 3));
          return LatLng(position.latitude, position.longitude);
        } catch (_) {
          // Last resort: try to get last known position
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            return LatLng(lastPosition.latitude, lastPosition.longitude);
          }
          return null;
        }
      }
    } catch (e) {
      print('Error getting high accuracy location: $e');
      return null;
    }
  }

  /// Location stream that works on both web and native platforms.
  /// On web, falls back to periodic polling if stream fails.
  static Stream<LatLng> getLocationStream() {
    if (kIsWeb) {
      // On web, use periodic polling instead of stream (more reliable)
      return _webLocationStream();
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Polling-based location updates for web platform
  static Stream<LatLng> _webLocationStream() {
    late StreamController<LatLng> controller;
    Timer? timer;

    controller = StreamController<LatLng>(
      onListen: () {
        timer = Timer.periodic(const Duration(seconds: 10), (_) async {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 5));
            if (!controller.isClosed) {
              controller.add(LatLng(position.latitude, position.longitude));
            }
          } catch (e) {
            // Silently skip failed polls on web
            print('Web location poll skipped: $e');
          }
        });
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }
}

