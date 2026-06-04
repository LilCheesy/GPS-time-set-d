import 'package:json_annotation/json_annotation.dart';

part 'sos_request.g.dart';

@JsonSerializable()
class SosRequest {
  final double latitude;
  final double longitude;
  final int? userId;

  SosRequest({
    required this.latitude,
    required this.longitude,
    this.userId,
  });

  factory SosRequest.fromJson(Map<String, dynamic> json) =>
      _$SosRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SosRequestToJson(this);
}
