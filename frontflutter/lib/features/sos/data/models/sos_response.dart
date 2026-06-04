import 'package:json_annotation/json_annotation.dart';

part 'sos_response.g.dart';

@JsonSerializable()
class SosResponse {
  final int? facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final String? phone;
  final String? facilityType;
  final double? destLatitude;
  final double? destLongitude;
  final double? distanceMeters;
  final int? estimatedMinutes;
  final String status;
  final Map<String, String>? zMetadata;

  SosResponse({
    this.facilityId,
    this.facilityName,
    this.facilityAddress,
    this.phone,
    this.facilityType,
    this.destLatitude,
    this.destLongitude,
    this.distanceMeters,
    this.estimatedMinutes,
    required this.status,
    this.zMetadata,
  });

  factory SosResponse.fromJson(Map<String, dynamic> json) =>
      _$SosResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SosResponseToJson(this);

  bool get isSuccess => status == 'SUCCESS';
  bool get isNoFacilityFound => status == 'NO_FACILITY_FOUND';
}
