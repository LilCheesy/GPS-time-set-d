import 'package:frontflutter/core/utils/polyline_decoder.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';
import 'package:frontflutter/features/sos/data/models/sos_multi_response.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontflutter/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';
import 'package:frontflutter/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:frontflutter/features/sos/domain/repositories/sos_repository.dart';
import 'package:frontflutter/shared/providers/location_provider.dart';

// Providers

final sosRemoteDatasourceProvider = Provider(
  (ref) => SosRemoteDatasource(dio: Dio()),
);

final sosRepositoryProvider = Provider(
  (ref) => SosRepositoryImpl(ref.watch(sosRemoteDatasourceProvider)),
);

final currentLocationProvider =
    StreamProvider<LatLng>((ref) => LocationProvider.getLocationStream());

// State classes

class SosState {
  final SosResponse? sosResponse;
  final SosMultiResponse? scanResponse;
  final List<FacilityInfo> facilities;
  final FacilityInfo? selectedFacility;
  final TrackAsiaRoute? route;
  final bool isLoading;
  final bool isScanning;
  final bool isFetchingRoute;
  final String? error;
  final List<LatLng> polylinePoints;
  final int currentPolylineIndex;
  final LatLng? currentLocation;
  final int? routeEtaMinutes;
  final double? routeDistanceMeters;

  SosState({
    this.sosResponse,
    this.scanResponse,
    this.facilities = const [],
    this.selectedFacility,
    this.route,
    this.isLoading = false,
    this.isScanning = false,
    this.isFetchingRoute = false,
    this.error,
    this.polylinePoints = const [],
    this.currentPolylineIndex = 0,
    this.currentLocation,
    this.routeEtaMinutes,
    this.routeDistanceMeters,
  });

  /// Whether we are in navigation mode (facility selected + route loaded)
  bool get isNavigating =>
      selectedFacility != null && route != null && polylinePoints.isNotEmpty;

  /// Whether we have scan results to show
  bool get hasScanResults => facilities.isNotEmpty;

  SosState copyWith({
    SosResponse? sosResponse,
    SosMultiResponse? scanResponse,
    List<FacilityInfo>? facilities,
    FacilityInfo? selectedFacility,
    bool clearSelectedFacility = false,
    TrackAsiaRoute? route,
    bool clearRoute = false,
    bool? isLoading,
    bool? isScanning,
    bool? isFetchingRoute,
    String? error,
    bool clearError = false,
    List<LatLng>? polylinePoints,
    int? currentPolylineIndex,
    LatLng? currentLocation,
    int? routeEtaMinutes,
    bool clearRouteEta = false,
    double? routeDistanceMeters,
    bool clearRouteDistance = false,
  }) {
    return SosState(
      sosResponse: sosResponse ?? this.sosResponse,
      scanResponse: scanResponse ?? this.scanResponse,
      facilities: facilities ?? this.facilities,
      selectedFacility: clearSelectedFacility
          ? null
          : (selectedFacility ?? this.selectedFacility),
      route: clearRoute ? null : (route ?? this.route),
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      error: clearError ? null : (error ?? this.error),
      polylinePoints: polylinePoints ?? this.polylinePoints,
      currentPolylineIndex: currentPolylineIndex ?? this.currentPolylineIndex,
      currentLocation: currentLocation ?? this.currentLocation,
      routeEtaMinutes: clearRouteEta
          ? null
          : (routeEtaMinutes ?? this.routeEtaMinutes),
      routeDistanceMeters: clearRouteDistance
          ? null
          : (routeDistanceMeters ?? this.routeDistanceMeters),
    );
  }
}

// Notifier

class SosNotifier extends StateNotifier<SosState> {
  final SosRepository _repository;

  SosNotifier(this._repository) : super(SosState());

  /// Step 1: Scan for nearby facilities
  Future<void> scanFacilities({
    required double latitude,
    required double longitude,
    int? userId,
  }) async {
    state = state.copyWith(
      isScanning: true,
      clearError: true,
      // Reset previous navigation state
      clearSelectedFacility: true,
      clearRoute: true,
      polylinePoints: [],
      currentPolylineIndex: 0,
      clearRouteEta: true,
      clearRouteDistance: true,
    );

    try {
      final request = SosRequest(
        latitude: latitude,
        longitude: longitude,
        userId: userId,
      );

      final response = await _repository.scanFacilities(request);
      state = state.copyWith(
        scanResponse: response,
        facilities: response.facilities,
        isScanning: false,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
      );
    }
  }

  /// Step 2: User selects a facility → fetch route
  Future<void> selectFacility({
    required FacilityInfo facility,
    required double userLat,
    required double userLng,
  }) async {
    state = state.copyWith(
      selectedFacility: facility,
      isFetchingRoute: true,
      clearError: true,
      // Clear previous route
      clearRoute: true,
      polylinePoints: [],
      clearRouteEta: true,
      clearRouteDistance: true,
    );

    try {
      final route = await _repository.getRoute(
        userLat: userLat,
        userLng: userLng,
        destLat: facility.destLatitude!,
        destLng: facility.destLongitude!,
      );

      if (route.isSuccessful && route.routes.isNotEmpty) {
        final routeObj = route.routes.first;
        // Extract ETA from TrackAsia (duration is in seconds)
        final etaMinutes = (routeObj.duration / 60).ceil();
        final distanceMeters = routeObj.distance;

        state = state.copyWith(
          route: route,
          isFetchingRoute: false,
          routeEtaMinutes: etaMinutes,
          routeDistanceMeters: distanceMeters,
        );
      } else {
        state = state.copyWith(
          isFetchingRoute: false,
          error: 'Không tìm được đường đi. Thử cơ sở khác.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isFetchingRoute: false,
        error: 'Lỗi tìm đường: $e',
      );
    }
  }

  /// Legacy: Send SOS (single facility — backward compatibility)
  Future<void> sendSos({
    required double latitude,
    required double longitude,
    int? userId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

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
      );

      if (response.isSuccess) {
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

    // Update polyline index if navigating
    if (state.polylinePoints.isNotEmpty && state.isNavigating) {
      final closestIndex = PolylineDecoder.getClosestPointIndex(
        state.polylinePoints,
        location,
      );
      state = state.copyWith(currentPolylineIndex: closestIndex);
    }
  }

  void setPolylinePoints(List<LatLng> points) {
    state = state.copyWith(polylinePoints: points);
  }

  /// Go back to facility selection (clear route but keep scan results)
  void clearSelection() {
    state = state.copyWith(
      clearSelectedFacility: true,
      clearRoute: true,
      polylinePoints: [],
      currentPolylineIndex: 0,
      clearRouteEta: true,
      clearRouteDistance: true,
    );
  }

  void reset() {
    state = SosState();
  }
}

// Provider

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return SosNotifier(repository);
});
