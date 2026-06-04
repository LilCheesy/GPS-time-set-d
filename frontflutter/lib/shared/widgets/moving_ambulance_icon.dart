import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Utility to create a Marker representing the user's current location
class MovingAmbulanceIcon {
  /// Creates a [Marker] for the ambulance/user position on the map
  static Marker create({
    required LatLng currentLocation,
    double rotation = 0,
  }) {
    return Marker(
      point: currentLocation,
      width: 40,
      height: 40,
      child: _AmbulanceWidget(rotation: rotation),
    );
  }
}

class _AmbulanceWidget extends StatelessWidget {
  final double rotation;

  const _AmbulanceWidget({this.rotation = 0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade600,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_hospital,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Utility to create a pulsing Marker for location display
class PulsingLocationMarker {
  /// Creates a [Marker] with a pulsing animation effect
  static Marker create({
    required LatLng location,
    Color color = Colors.blue,
  }) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: _PulsingWidget(color: color),
    );
  }
}

class _PulsingWidget extends StatefulWidget {
  final Color color;

  const _PulsingWidget({required this.color});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(_controller),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.3),
          border: Border.all(
            color: widget.color,
            width: 2,
          ),
        ),
      ),
    );
  }
}
