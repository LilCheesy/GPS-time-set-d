import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong2.dart';
import 'package:polyline/polyline.dart' as polyline_lib;
import 'package:frontflutter/core/constants/app_constants.dart';
import 'package:frontflutter/features/sos/presentation/providers/sos_provider.dart';
import 'package:frontflutter/shared/providers/location_provider.dart';
import 'package:frontflutter/shared/widgets/sos_fab.dart';
import 'package:frontflutter/shared/widgets/moving_ambulance_icon.dart';

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
    if (location != null) {
      setState(() {
        _currentLocation = location;
      });
      _mapController.move(_currentLocation, AppConstants.defaultZoomLevel);
    }
  }

  void _handleSosPressed() async {
    final sosNotifier = ref.read(sosProvider.notifier);
    
    // Trigger SOS
    await sosNotifier.sendSos(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      userId: 1, // Replace with actual user ID from authentication
    );

    // Show bottom sheet with facility information
    _showFacilityInfo();
  }

  void _showFacilityInfo() {
    final sosState = ref.read(sosProvider);

    if (sosState.sosResponse?.isNoFacilityFound ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No medical facility found nearby.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) {
        final response = sosState.sosResponse;
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Route',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (sosState.isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                response?.facilityName ?? 'Loading...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                response?.facilityAddress ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions_car, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '${response?.distanceMeters?.toStringAsFixed(1) ?? 0} m • ~${response?.estimatedMinutes ?? 0} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    response?.phone ?? 'No phone',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updatePolyline() {
    final sosState = ref.read(sosProvider);
    if (sosState.route != null && sosState.route!.isSuccessful) {
      final geometry = sosState.route!.routes.first.geometry;
      try {
        final decoded = polyline_lib.Polyline.fromEncoded(
          geometry,
          precision: 6,
        );
        setState(() {
          _polylinePoints = decoded.coordinates
              .map((coord) => LatLng(coord[0], coord[1]))
              .toList();
        });
        ref.read(sosProvider.notifier).setPolylinePoints(_polylinePoints);
      } catch (e) {
        print('Error decoding polyline: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final currentLocationAsync = ref.watch(currentLocationProvider);

    // Update current location when stream updates
    currentLocationAsync.whenData((location) {
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
        ref.read(sosProvider.notifier).updateCurrentLocation(location);
      }
    });

    // Update polyline when route changes
    ref.listen(sosProvider, (previous, next) {
      if (previous?.route != next.route) {
        _updatePolyline();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('🏥 CareBridge SOS'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: AppConstants.defaultZoomLevel,
              minZoom: AppConstants.minZoomLevel,
              maxZoom: AppConstants.maxZoomLevel,
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Facility marker
              if (sosState.sosResponse?.isSuccess ?? false)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        sosState.sosResponse!.destLatitude!,
                        sosState.sosResponse!.destLongitude!,
                      ),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.hospital_box,
                        color: Colors.red.shade600,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              // Polylines
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Traveled path (grey)
                    if (sosState.currentPolylineIndex > 0)
                      Polyline(
                        points: _polylinePoints
                            .sublist(0, sosState.currentPolylineIndex),
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
              // Current location marker
              MarkerLayer(
                markers: [
                  MovingAmbulanceIcon(
                    currentLocation: _currentLocation,
                  ),
                ],
              ),
            ],
          ),
          // Info panel (top)
          if (sosState.sosResponse?.isSuccess ?? false)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route to ${sosState.sosResponse?.facilityName ?? 'facility'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ETA: ~${sosState.sosResponse?.estimatedMinutes ?? 0} min',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Error message
          if (sosState.error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade600,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    sosState.error!,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: SosFAB(
        onPressed: _handleSosPressed,
        isLoading: sosState.isLoading,
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
