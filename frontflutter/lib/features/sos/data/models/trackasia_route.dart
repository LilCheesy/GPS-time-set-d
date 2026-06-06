import 'package:json_annotation/json_annotation.dart';

part 'trackasia_route.g.dart';

@JsonSerializable()
class TrackAsiaRoute {
  final List<RouteObject> routes;
  final String code;

  TrackAsiaRoute({
    required this.routes,
    required this.code,
  });

  factory TrackAsiaRoute.fromJson(Map<String, dynamic> json) =>
      _$TrackAsiaRouteFromJson(json);

  Map<String, dynamic> toJson() => _$TrackAsiaRouteToJson(this);

  bool get isSuccessful => code == 'Ok' && routes.isNotEmpty;
}

@JsonSerializable()
class RouteObject {
  final dynamic geometry; // Changed to dynamic to support geojson Map
  final List<Leg> legs;
  final double distance;
  final double duration;

  RouteObject({
    required this.geometry,
    required this.legs,
    required this.distance,
    required this.duration,
  });

  factory RouteObject.fromJson(Map<String, dynamic> json) =>
      _$RouteObjectFromJson(json);

  Map<String, dynamic> toJson() => _$RouteObjectToJson(this);
}

@JsonSerializable()
class Leg {
  final List<Step> steps;
  final double distance;
  final double duration;

  Leg({
    required this.steps,
    required this.distance,
    required this.duration,
  });

  factory Leg.fromJson(Map<String, dynamic> json) => _$LegFromJson(json);

  Map<String, dynamic> toJson() => _$LegToJson(this);
}

@JsonSerializable()
class Step {
  final dynamic geometry; // Changed to dynamic to support geojson
  final double distance;
  final double duration;
  final String? name;
  final Maneuver? maneuver;

  Step({
    required this.geometry,
    required this.distance,
    required this.duration,
    this.name,
    this.maneuver,
  });

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);

  Map<String, dynamic> toJson() => _$StepToJson(this);
}

@JsonSerializable()
class Maneuver {
  final String? instruction;
  final String? type;
  final String? modifier;

  Maneuver({
    this.instruction,
    this.type,
    this.modifier,
  });

  factory Maneuver.fromJson(Map<String, dynamic> json) => _$ManeuverFromJson(json);

  Map<String, dynamic> toJson() => _$ManeuverToJson(this);
}
