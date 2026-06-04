import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class MovingAmbulanceIcon extends StatefulWidget {
  final LatLng currentLocation;
  final double rotation;

  const MovingAmbulanceIcon({
    required this.currentLocation,
    this.rotation = 0,
    Key? key,
  }) : super(key: key);

  @override
  State<MovingAmbulanceIcon> createState() => _MovingAmbulanceIconState();
}

class _MovingAmbulanceIconState extends State<MovingAmbulanceIcon> {
  @override
  Widget build(BuildContext context) {
    return Marker(
      point: widget.currentLocation,
      width: 40,
      height: 40,
      child: Transform.rotate(
        angle: widget.rotation,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade600,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.local_hospital,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Rotating pulse effect for the marker
class PulsingMarker extends StatefulWidget {
  final LatLng location;
  final Color color;

  const PulsingMarker({
    required this.location,
    this.color = Colors.blue,
    Key? key,
  }) : super(key: key);

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
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
    return Marker(
      point: widget.location,
      width: 50,
      height: 50,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.2).animate(_controller),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3),
            border: Border.all(
              color: widget.color,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
