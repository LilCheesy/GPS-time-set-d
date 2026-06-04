import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong2.dart';
import 'package:frontflutter/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';
import 'package:frontflutter/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:frontflutter/shared/providers/location_provider.dart';

// Providers

final sosRemoteDatasourceProvider = Provider(
  (ref) => SosRemoteDatasource(dio: Dio()),
);

final sosRepositoryProvider = Provider(
  (ref) => SosRepositoryImpl(ref.watch(sosRemoteDatasourceProvider)),
);

final currentLocationProvider =
    StreamProvider<LatLng?>((ref) => LocationProvider.getLocationStream().startWith(null));

// State classes

class SosState {
  final SosResponse? sosResponse;
  final TrackAsiaRoute? route;
  final bool isLoading;
  final String? error;
  final List<LatLng> polylinePoints;
  final int currentPolylineIndex;
  final LatLng? currentLocation;

  SosState({
    this.sosResponse,
    this.route,
    this.isLoading = false,
    this.error,
    this.polylinePoints = const [],
    this.currentPolylineIndex = 0,
    this.currentLocation,
  });

  SosState copyWith({
    SosResponse? sosResponse,
    TrackAsiaRoute? route,
    bool? isLoading,
    String? error,
    List<LatLng>? polylinePoints,
    int? currentPolylineIndex,
    LatLng? currentLocation,
  }) {
    return SosState(
      sosResponse: sosResponse ?? this.sosResponse,
      route: route ?? this.route,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      currentPolylineIndex: currentPolylineIndex ?? this.currentPolylineIndex,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

// Notifier

class SosNotifier extends StateNotifier<SosState> {
  final SosRepositoryImpl _repository;

  SosNotifier(this._repository) : super(SosState());

  Future<void> sendSos({
    required double latitude,
    required double longitude,
    int? userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = SosRequest(
        latitude: latitude,
        longitude: longitude,
        userId: userId,
      );

      final response = await _repository.sendSos(request);
      state = state.copyWith(
        sosResponse: response,
        isLoading: false,
        error: null,
      );

      if (response.isSuccess) {
        // Automatically fetch route after SOS is sent
        await fetchRoute(
          userLat: latitude,
          userLng: longitude,
          destLat: response.destLatitude!,
          destLng: response.destLongitude!,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchRoute({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final route = await _repository.getRoute(
        userLat: userLat,
        userLng: userLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (route.isSuccessful && route.routes.isNotEmpty) {
        // Decode polyline from first route
        final geometry = route.routes.first.geometry;
        // Polyline decoding will be done in the UI layer
        state = state.copyWith(route: route);
      } else {
        state = state.copyWith(
          error: 'Failed to fetch route',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Route fetch error: $e',
      );
    }
  }

  void updateCurrentLocation(LatLng location) {
    state = state.copyWith(currentLocation: location);

    // Update polyline index if we have polyline points
    if (state.polylinePoints.isNotEmpty && state.sosResponse?.isSuccess == true) {
      // Find closest point on polyline
      double minDistance = double.infinity;
      int closestIndex = 0;

      for (int i = 0; i < state.polylinePoints.length; i++) {
        final point = state.polylinePoints[i];
        final distance = _haversineDistance(
          location.latitude,
          location.longitude,
          point.latitude,
          point.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }

      state = state.copyWith(currentPolylineIndex: closestIndex);
    }
  }

  void setPolylinePoints(List<LatLng> points) {
    state = state.copyWith(polylinePoints: points);
  }

  void reset() {
    state = SosState();
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
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

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

// Provider

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return SosNotifier(repository as SosRepositoryImpl);
});
