import 'package:flutter/material.dart';
import 'package:frontflutter/features/sos/data/models/facility_info.dart';

/// Bottom sheet that displays a list of nearby medical facilities
/// for the user to choose from.
class FacilityListSheet extends StatefulWidget {
  final List<FacilityInfo> facilities;
  final FacilityInfo? selectedFacility;
  final bool isLoading;

  const FacilityListSheet({
    required this.facilities,
    this.selectedFacility,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  /// Show the facility list as a modal bottom sheet.
  /// Returns the selected [FacilityInfo] or null if dismissed.
  static Future<FacilityInfo?> show(
    BuildContext context, {
    required List<FacilityInfo> facilities,
    FacilityInfo? selectedFacility,
  }) {
    return showModalBottomSheet<FacilityInfo>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacilityListSheet(
        facilities: facilities,
        selectedFacility: selectedFacility,
      ),
    );
  }

  @override
  State<FacilityListSheet> createState() => _FacilityListSheetState();
}

class _FacilityListSheetState extends State<FacilityListSheet> {
  FacilityInfo? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedFacility ?? widget.facilities.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.red.shade600, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Cơ sở y tế gần bạn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.facilities.length} kết quả',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // Facility list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: widget.facilities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final facility = widget.facilities[index];
                final isSelected = _selected?.facilityId == facility.facilityId;
                final isRecommended = index == 0;

                return _FacilityCard(
                  facility: facility,
                  isSelected: isSelected,
                  isRecommended: isRecommended,
                  onTap: () {
                    setState(() => _selected = facility);
                  },
                );
              },
            ),
          ),
          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _selected != null
                    ? () => Navigator.pop(context, _selected)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  'Chọn & Dẫn đường',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final FacilityInfo facility;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _FacilityCard({
    required this.facility,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.red.shade600 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.red.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Facility info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          facility.facilityName ?? 'Unknown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Gần nhất',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    facility.facilityAddress ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.directions_car,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        facility.formattedDistance,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        facility.formattedEta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (facility.facilityType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility.facilityType!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.blue.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
