// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_multi_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosMultiResponse _$SosMultiResponseFromJson(Map<String, dynamic> json) =>
    SosMultiResponse(
      status: json['status'] as String,
      facilities: (json['facilities'] as List<dynamic>)
          .map((e) => FacilityInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      zMetadata: (json['zMetadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$SosMultiResponseToJson(SosMultiResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'facilities': instance.facilities,
      'zMetadata': instance.zMetadata,
    };
