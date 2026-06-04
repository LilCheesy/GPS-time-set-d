import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontflutter/core/constants/app_constants.dart';
import 'package:frontflutter/core/utils/polyline_decoder.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';
import 'package:frontflutter/features/sos/presentation/providers/sos_provider.dart';
import 'package:frontflutter/shared/providers/location_provider.dart';
import 'package:frontflutter/shared/widgets/facility_list_sheet.dart';
import 'package:frontflutter/shared/widgets/moving_ambulance_icon.dart';
import 'package:frontflutter/shared/widgets/navigation_info_panel.dart';
import 'package:frontflutter/shared/widgets/sos_fab.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  late MapController _mapController;
  LatLng _currentLocation =
      LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  List<LatLng> _polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final location = await LocationProvider.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
      _mapController.move(_currentLocation, AppConstants.defaultZoomLevel);
    }
  }

  /// SOS button pressed → get accurate GPS → scan facilities → show list
  void _handleSosPressed() async {
    // Step 1: Get high-accuracy GPS location
    final accurateLocation = await LocationProvider.getHighAccuracyLocation();
    if (accurateLocation != null && mounted) {
      setState(() {
        _currentLocation = accurateLocation;
      });
    }

    if (!mounted) return;

    // Step 2: Scan for nearby facilities
    final sosNotifier = ref.read(sosProvider.notifier);
    await sosNotifier.scanFacilities(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      userId: 1, // TODO: Replace with actual user ID from authentication
    );

    if (!mounted) return;

    // Step 3: Show facility list bottom sheet
    final sosState = ref.read(sosProvider);
    if (sosState.scanResponse?.isNoFacilityFound ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy cơ sở y tế gần bạn.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (sosState.hasScanResults) {
      // Fit map to show all facility markers
      _fitMapToFacilities(sosState.facilities);
      
      // Auto-select the nearest facility (first in the list) and find route
      final nearestFacility = sosState.facilities.first;
      await sosNotifier.selectFacility(
        facility: nearestFacility,
        userLat: _currentLocation.latitude,
        userLng: _currentLocation.longitude,
      );
    }
  }

  /// Show the facility list bottom sheet
  void _showFacilitySelection() async {
    final sosState = ref.read(sosProvider);
    final selected = await FacilityListSheet.show(
      context,
      facilities: sosState.facilities,
      selectedFacility: sosState.selectedFacility,
    );

    if (selected != null && mounted) {
      // User selected a facility → fetch route
      final sosNotifier = ref.read(sosProvider.notifier);
      await sosNotifier.selectFacility(
        facility: selected,
        userLat: _currentLocation.latitude,
        userLng: _currentLocation.longitude,
      );
    }
  }

  /// Fit map camera to show all scanned facilities + user location
  void _fitMapToFacilities(List<FacilityInfo> facilities) {
    final points = <LatLng>[_currentLocation];
    for (final f in facilities) {
      if (f.destLatitude != null && f.destLongitude != null) {
        points.add(LatLng(f.destLatitude!, f.destLongitude!));
      }
    }
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    }
  }

  /// Decode and display polyline when route changes
  void _updatePolyline() {
    final sosState = ref.read(sosProvider);
    if (sosState.route != null && sosState.route!.isSuccessful) {
      final geometry = sosState.route!.routes.first.geometry;
      final decoded = PolylineDecoder.decodePolyline(geometry);
      if (decoded.isNotEmpty) {
        setState(() {
          _polylinePoints = decoded;
        });
        ref.read(sosProvider.notifier).setPolylinePoints(_polylinePoints);

        // Fit map to show entire route
        if (_polylinePoints.length >= 2) {
          final bounds = LatLngBounds.fromPoints(_polylinePoints);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);

    // Listen for location updates
    ref.listen<AsyncValue<LatLng>>(currentLocationProvider, (previous, next) {
      next.whenData((location) {
        setState(() {
          _currentLocation = location;
        });
        ref.read(sosProvider.notifier).updateCurrentLocation(location);
      });
    });

    // Listen for route changes → decode polyline
    ref.listen(sosProvider, (previous, next) {
      if (previous?.route != next.route && next.route != null) {
        _updatePolyline();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 CareBridge SOS'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // ─── MAP ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: AppConstants.defaultZoomLevel,
              minZoom: AppConstants.minZoomLevel.toDouble(),
              maxZoom: AppConstants.maxZoomLevel.toDouble(),
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carebrigde.frontflutter',
              ),
              // Polylines (traveled = grey, remaining = red)
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Traveled path (grey)
                    if (sosState.currentPolylineIndex > 0)
                      Polyline(
                        points: _polylinePoints
                            .sublist(0, sosState.currentPolylineIndex + 1),
                        color: Colors.grey,
                        strokeWidth: 8,
                      ),
                    // Remaining path (red)
                    Polyline(
                      points: _polylinePoints
                          .sublist(sosState.currentPolylineIndex),
                      color: Colors.red.shade600,
                      strokeWidth: 8,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // All scanned facility markers (grey, smaller)
                  if (sosState.hasScanResults)
                    ...sosState.facilities
                        .where((f) =>
                            f.facilityId !=
                            sosState.selectedFacility?.facilityId)
                        .map((f) => Marker(
                              point:
                                  LatLng(f.destLatitude!, f.destLongitude!),
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.grey.shade500,
                                size: 24,
                              ),
                            )),
                  // Selected facility marker (red, larger)
                  if (sosState.selectedFacility != null)
                    Marker(
                      point: LatLng(
                        sosState.selectedFacility!.destLatitude!,
                        sosState.selectedFacility!.destLongitude!,
                      ),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade600,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  // User/ambulance marker
                  MovingAmbulanceIcon.create(
                    currentLocation: _currentLocation,
                  ),
                ],
              ),
            ],
          ),

          // ─── NAVIGATION INFO PANEL (shown when navigating) ───
          if (sosState.isNavigating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationInfoPanel(
                facility: sosState.selectedFacility!,
                routeEtaMinutes: sosState.routeEtaMinutes,
                routeDistanceMeters: sosState.routeDistanceMeters,
                onChangeFacility: () {
                  ref.read(sosProvider.notifier).clearSelection();
                  setState(() {
                    _polylinePoints = [];
                  });
                  _fitMapToFacilities(sosState.facilities);
                  _showFacilitySelection();
                },
              ),
            ),

          // ─── LOADING INDICATOR (scanning or fetching route) ───
          if (sosState.isScanning || sosState.isFetchingRoute)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        sosState.isScanning
                            ? 'Đang quét cơ sở y tế...'
                            : 'Đang tìm đường...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── ERROR MESSAGE ───
          if (sosState.error != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sosState.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: SosFAB(
        onPressed: _handleSosPressed,
        isLoading: sosState.isScanning,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
