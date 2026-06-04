// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosResponse _$SosResponseFromJson(Map<String, dynamic> json) => SosResponse(
  facilityId: (json['facilityId'] as num?)?.toInt(),
  facilityName: json['facilityName'] as String?,
  facilityAddress: json['facilityAddress'] as String?,
  phone: json['phone'] as String?,
  facilityType: json['facilityType'] as String?,
  destLatitude: (json['destLatitude'] as num?)?.toDouble(),
  destLongitude: (json['destLongitude'] as num?)?.toDouble(),
  distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
  status: json['status'] as String,
  zMetadata: (json['zMetadata'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$SosResponseToJson(SosResponse instance) =>
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
      'status': instance.status,
      'zMetadata': instance.zMetadata,
    };
