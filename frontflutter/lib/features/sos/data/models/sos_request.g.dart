// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosRequest _$SosRequestFromJson(Map<String, dynamic> json) => SosRequest(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  userId: (json['userId'] as num?)?.toInt(),
);

Map<String, dynamic> _$SosRequestToJson(SosRequest instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'userId': instance.userId,
    };
