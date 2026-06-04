// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FacilityInfo _$FacilityInfoFromJson(Map<String, dynamic> json) => FacilityInfo(
  facilityId: (json['facilityId'] as num?)?.toInt(),
  facilityName: json['facilityName'] as String?,
  facilityAddress: json['facilityAddress'] as String?,
  phone: json['phone'] as String?,
  facilityType: json['facilityType'] as String?,
  destLatitude: (json['destLatitude'] as num?)?.toDouble(),
  destLongitude: (json['destLongitude'] as num?)?.toDouble(),
  distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$FacilityInfoToJson(FacilityInfo instance) =>
    <String, dynamic>{
      'facilityId': instance.facilityId,
      'facilityName': instance.facilityName,
      'facilityAddress': instance.facilityAddress,
      'phone': instance.phone,
      'facilityType': instance.facilityType,
      'destLatitude': instance.destLatitude,
      'destLongitude': instance.destLongitude,
      'distanceMeters': instance.distanceMeters,
      'estimatedMinutes': instance.estimatedMinutes,
    };
