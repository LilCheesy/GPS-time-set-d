import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:frontflutter/core/constants/app_constants.dart';
import 'package:frontflutter/core/utils/polyline_decoder.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';
import 'package:frontflutter/features/sos/presentation/providers/sos_provider.dart';
import 'package:frontflutter/shared/providers/location_provider.dart';
import 'package:frontflutter/shared/widgets/facility_list_sheet.dart';
import 'package:frontflutter/shared/widgets/navigation_info_panel.dart';
import 'package:frontflutter/shared/widgets/sos_fab.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  MapLibreMapController? _mapController;
  bool _isStyleLoaded = false;
  LatLng _currentLocation =
      LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  List<LatLng> _polylinePoints = [];
  bool _locationObtained = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Try up to 3 times to get the real location
    for (int attempt = 1; attempt <= 3; attempt++) {
      final location = await LocationProvider.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _locationObtained = true;
        });
        _mapController?.moveCamera(
          CameraUpdate.newLatLngZoom(_currentLocation, AppConstants.defaultZoomLevel),
        );
        _drawMapLayers();
        return;
      }
      // Wait a bit before retrying
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // All attempts failed — show warning to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Không lấy được vị trí. Vui lòng cấp quyền truy cập vị trí và bật định vị trên thiết bị/trình duyệt.',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _initializeLocation,
          ),
        ),
      );
    }
  }

  /// SOS button pressed → get accurate GPS → scan facilities → show list
  void _handleSosPressed() async {
    // Step 1: Get real-time GPS location
    LatLng? accurateLocation = await LocationProvider.getHighAccuracyLocation();

    // If high accuracy fails, try normal accuracy
    if (accurateLocation == null) {
      accurateLocation = await LocationProvider.getCurrentLocation();
    }

    if (accurateLocation != null && mounted) {
      setState(() {
        _currentLocation = accurateLocation!;
        _locationObtained = true;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, AppConstants.defaultZoomLevel),
      );
      _drawMapLayers();
    } else if (!_locationObtained && mounted) {
      // Still no location at all — warn user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '❌ Không thể xác định vị trí. Vui lòng bật định vị trên thiết bị/trình duyệt rồi thử lại.',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
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

    // Step 3: Check results and show facility list or errors
    final sosState = ref.read(sosProvider);
    
    if (sosState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: ${sosState.error}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      _drawMapLayers();
      
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
    if (_mapController == null) return;
    
    final points = <LatLng>[_currentLocation];
    for (final f in facilities) {
      if (f.destLatitude != null && f.destLongitude != null) {
        points.add(LatLng(f.destLatitude!, f.destLongitude!));
      }
    }
    if (points.length >= 2) {
      double minLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLat = points[0].latitude;
      double maxLng = points[0].longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, left: 60, top: 60, right: 60, bottom: 60),
      );
    }
  }

  /// Decode and display polyline when route changes
  void _updatePolyline() {
    final sosState = ref.read(sosProvider);
    if (sosState.route != null && sosState.route!.isSuccessful) {
      final geometry = sosState.route!.routes.first.geometry;
      List<LatLng> decoded = [];

      if (geometry is Map<String, dynamic> && geometry['type'] == 'LineString') {
        final coords = geometry['coordinates'] as List;
        for (final c in coords) {
          // GeoJSON is [longitude, latitude]
          decoded.add(LatLng(c[1].toDouble(), c[0].toDouble()));
        }
      } else if (geometry is String) {
        decoded = PolylineDecoder.decodePolyline(geometry);
      }

      if (decoded.isNotEmpty) {
        setState(() {
          _polylinePoints = decoded;
        });
        ref.read(sosProvider.notifier).setPolylinePoints(_polylinePoints);

        // Fit map to show route center to avoid Web newLatLngBounds bugs
        if (_polylinePoints.length >= 2) {
          double minLat = _polylinePoints[0].latitude;
          double minLng = _polylinePoints[0].longitude;
          double maxLat = _polylinePoints[0].latitude;
          double maxLng = _polylinePoints[0].longitude;
          for (final p in _polylinePoints) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLng) minLng = p.longitude;
            if (p.longitude > maxLng) maxLng = p.longitude;
          }
          if (!sosState.isNavigationStarted) {
            final bounds = LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            );
            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(
                bounds, 
                left: 60, 
                top: 280, 
                right: 60, 
                bottom: 150,
              ),
            );
          }
        }
        
        _drawMapLayers();
      }
    }
  }

  void _startNavigation() {
    ref.read(sosProvider.notifier).startNavigation();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: _currentLocation,
        zoom: 17.0,
        tilt: 45.0, // Tilt the camera for navigation view
      )),
    );
  }

  Future<void> _drawMapLayers() async {
    if (_mapController == null || !_isStyleLoaded) return;
    
    final sosState = ref.read(sosProvider);
    
    try {
      await _mapController!.clearLines();
      await _mapController!.clearCircles();
      await _mapController!.clearSymbols(); // Clear old symbols
      
      // Draw route using addLine (most reliable on mobile)
      if (_polylinePoints.isNotEmpty) {
        if (sosState.currentPolylineIndex > 0 && sosState.currentPolylineIndex < _polylinePoints.length) {
          await _mapController!.addLine(LineOptions(
            geometry: _polylinePoints.sublist(0, sosState.currentPolylineIndex + 1),
            lineColor: "#9E9E9E", // grey for passed route
            lineWidth: 5.0,
            lineJoin: "round",
          ));
        }

        if (sosState.currentPolylineIndex < _polylinePoints.length) {
          await _mapController!.addLine(LineOptions(
            geometry: _polylinePoints.sublist(sosState.currentPolylineIndex),
            lineColor: "#3887be", // TrackAsia signature blue
            lineWidth: 5.0,
            lineJoin: "round",
          ));
        }
      }

      // Draw facilities using custom hospital marker
      if (sosState.hasScanResults) {
        for (final f in sosState.facilities) {
          if (f.facilityId != sosState.selectedFacility?.facilityId) {
            final latLng = LatLng(f.destLatitude!, f.destLongitude!);
            await _mapController!.addSymbol(SymbolOptions(
              geometry: latLng,
              iconImage: "hospital-normal",
              iconSize: 1.0,
            ));
          }
        }
      }

      // Selected facility
      if (sosState.selectedFacility != null) {
        final latLng = LatLng(sosState.selectedFacility!.destLatitude!, sosState.selectedFacility!.destLongitude!);
        await _mapController!.addSymbol(SymbolOptions(
          geometry: latLng,
          iconImage: "hospital-selected",
          iconSize: 1.0,
        ));
      }
      
      // User location
      await _mapController!.addCircle(CircleOptions(
        geometry: _currentLocation,
        circleColor: "#1E88E5", // blue.shade600
        circleRadius: 12.0,
        circleStrokeColor: "#ffffff",
        circleStrokeWidth: 3.0,
      ));
    } catch (e) {
      debugPrint("Error drawing map layers: $e");
      // If annotation manager isn't ready on web, retry after a short delay
      if (e.toString().contains("Annotation Manager has not been initialized")) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _drawMapLayers();
        });
      }
    }
  }

  Future<Uint8List> _createHospitalMarker({bool isSelected = false}) async {
    final double size = isSelected ? 80.0 : 50.0;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Circle background
    final Paint bgPaint = Paint()..color = isSelected ? const Color(0xFFE53935) : const Color(0xFF9E9E9E);
    canvas.drawCircle(Offset(size/2, size/2), size/2, bgPaint);
    
    // White cross
    final Paint crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = isSelected ? 8.0 : 5.0
      ..strokeCap = StrokeCap.round;
      
    final double center = size / 2;
    final double length = size / 5;
    
    // Horizontal line
    canvas.drawLine(Offset(center - length, center), Offset(center + length, center), crossPaint);
    // Vertical line
    canvas.drawLine(Offset(center, center - length), Offset(center, center + length), crossPaint);
    
    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() async {
    setState(() {
      _isStyleLoaded = true;
    });
    
    // Register custom markers
    try {
      final normalMarker = await _createHospitalMarker(isSelected: false);
      final selectedMarker = await _createHospitalMarker(isSelected: true);
      await _mapController!.addImage("hospital-normal", normalMarker);
      await _mapController!.addImage("hospital-selected", selectedMarker);
    } catch (e) {
      debugPrint("Failed to load custom markers: $e");
    }

    _drawMapLayers();
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
        _drawMapLayers();
      });
    });

    // Listen for route changes → decode polyline
    ref.listen(sosProvider, (previous, next) {
      if (previous?.route != next.route && next.route != null) {
        _updatePolyline();
      } else if (previous?.currentPolylineIndex != next.currentPolylineIndex) {
        // Redraw route with new colors as we move
        _drawMapLayers();
      } else if (previous?.selectedFacility != next.selectedFacility) {
        _drawMapLayers();
      } else if (previous?.isNavigationStarted != next.isNavigationStarted && next.isNavigationStarted) {
        // Redraw layers when navigation starts to show/hide UI components if needed
        _drawMapLayers();
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
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: AppConstants.defaultZoomLevel,
            ),
            styleString: 'https://maps.track-asia.com/styles/v2/streets.json?key=${dotenv.env['TRACKASIA_API_KEY'] ?? ''}',
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: false,
          ),

          // ─── NAVIGATION INFO PANEL (shown when navigating) ───
          if (sosState.selectedFacility != null && sosState.route != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationInfoPanel(
                facility: sosState.selectedFacility!,
                routeEtaMinutes: sosState.routeEtaMinutes,
                routeDistanceMeters: sosState.routeDistanceMeters,
                currentInstruction: sosState.currentInstruction,
                isNavigationStarted: sosState.isNavigationStarted,
                onChangeFacility: () {
                  ref.read(sosProvider.notifier).clearSelection();
                  setState(() {
                    _polylinePoints = [];
                  });
                  // Quay về vị trí trung tâm của người dùng
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation, AppConstants.defaultZoomLevel),
                  );
                  _showFacilitySelection();
                  _drawMapLayers();
                },
                onStartNavigation: _startNavigation,
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
                  padding: const EdgeInsets.all(16),
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
    // _mapController handles its own dispose via the plugin when removed, 
    // but if we needed, we'd dispose it here.
    super.dispose();
  }
}
