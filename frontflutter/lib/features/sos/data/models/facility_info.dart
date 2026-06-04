import 'package:json_annotation/json_annotation.dart';

part 'facility_info.g.dart';

@JsonSerializable()
class FacilityInfo {
  final int? facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final String? phone;
  final String? facilityType;
  final double? destLatitude;
  final double? destLongitude;
  final double? distanceMeters;
  final int? estimatedMinutes;

  FacilityInfo({
    this.facilityId,
    this.facilityName,
    this.facilityAddress,
    this.phone,
    this.facilityType,
    this.destLatitude,
    this.destLongitude,
    this.distanceMeters,
    this.estimatedMinutes,
  });

  factory FacilityInfo.fromJson(Map<String, dynamic> json) =>
      _$FacilityInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FacilityInfoToJson(this);

  /// Format distance for display (m or km)
  String get formattedDistance {
    if (distanceMeters == null) return '—';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters!.toStringAsFixed(0)} m';
  }

  /// Format ETA for display
  String get formattedEta {
    if (estimatedMinutes == null || estimatedMinutes == 0) return '< 1 phút';
    return '~$estimatedMinutes phút';
  }
}
