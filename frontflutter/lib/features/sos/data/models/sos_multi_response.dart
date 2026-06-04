import 'package:json_annotation/json_annotation.dart';
import 'facility_info.dart';

part 'sos_multi_response.g.dart';

@JsonSerializable()
class SosMultiResponse {
  final String status;
  final List<FacilityInfo> facilities;
  final Map<String, String>? zMetadata;

  SosMultiResponse({
    required this.status,
    required this.facilities,
    this.zMetadata,
  });

  factory SosMultiResponse.fromJson(Map<String, dynamic> json) =>
      _$SosMultiResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SosMultiResponseToJson(this);

  bool get isSuccess => status == 'SUCCESS';
  bool get isNoFacilityFound => status == 'NO_FACILITY_FOUND';
  bool get hasFacilities => isSuccess && facilities.isNotEmpty;
}
