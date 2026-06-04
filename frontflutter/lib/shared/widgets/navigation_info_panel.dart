import 'package:flutter/material.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';

/// Panel displayed on top of the map showing navigation info
/// after the user has selected a facility and route is loaded.
class NavigationInfoPanel extends StatelessWidget {
  final FacilityInfo facility;
  final int? routeEtaMinutes;
  final double? routeDistanceMeters;
  final VoidCallback onChangeFacility;

  const NavigationInfoPanel({
    required this.facility,
    this.routeEtaMinutes,
    this.routeDistanceMeters,
    required this.onChangeFacility,
    Key? key,
  }) : super(key: key);

  String get _displayEta {
    if (routeEtaMinutes != null) {
      return '~$routeEtaMinutes phút';
    }
    return facility.formattedEta;
  }

  String get _displayDistance {
    if (routeDistanceMeters != null) {
      if (routeDistanceMeters! >= 1000) {
        return '${(routeDistanceMeters! / 1000).toStringAsFixed(1)} km';
      }
      return '${routeDistanceMeters!.toStringAsFixed(0)} m';
    }
    return facility.formattedDistance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility name + type badge
          Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.red.shade600, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  facility.facilityName ?? 'Cơ sở y tế',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Distance + ETA
          Row(
            children: [
              _InfoChip(
                icon: Icons.directions_car,
                label: _displayDistance,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.access_time,
                label: _displayEta,
                color: Colors.orange,
              ),
              const Spacer(),
              // Change facility button
              TextButton.icon(
                onPressed: onChangeFacility,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text(
                  'Đổi',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
