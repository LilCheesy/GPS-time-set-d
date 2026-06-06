import 'package:flutter/material.dart';
import 'package:frontflutter/core/constants/app_constants.dart';

/// Utility widget for displaying the user's current location (ambulance icon) on the map.
///
/// This is used as a widget overlay on top of [TrackasiaMap] rather than
/// a native map marker, because trackasia_gl does not support Flutter widget
/// markers the way flutter_map did.
class MovingAmbulanceIcon extends StatelessWidget {
  const MovingAmbulanceIcon({super.key, this.rotation = 0.0, this.size = 40.0});

  final double rotation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
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

/// Utility widget for a pulsing location dot (used as overlay on [TrackasiaMap]).
class PulsingLocationMarker extends StatefulWidget {
  const PulsingLocationMarker({super.key, this.color = Colors.blue, this.size = 50.0});

  final Color color;
  final double size;

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker>
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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.3),
          border: Border.all(color: widget.color, width: 2),
        ),
      ),
    );
  }
}
