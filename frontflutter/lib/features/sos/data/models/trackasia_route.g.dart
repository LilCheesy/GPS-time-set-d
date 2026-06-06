// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trackasia_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackAsiaRoute _$TrackAsiaRouteFromJson(Map<String, dynamic> json) =>
    TrackAsiaRoute(
      routes: (json['routes'] as List<dynamic>)
          .map((e) => RouteObject.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$TrackAsiaRouteToJson(TrackAsiaRoute instance) =>
    <String, dynamic>{'routes': instance.routes, 'code': instance.code};

RouteObject _$RouteObjectFromJson(Map<String, dynamic> json) => RouteObject(
  geometry: json['geometry'],
  legs: (json['legs'] as List<dynamic>)
      .map((e) => Leg.fromJson(e as Map<String, dynamic>))
      .toList(),
  distance: (json['distance'] as num).toDouble(),
  duration: (json['duration'] as num).toDouble(),
);

Map<String, dynamic> _$RouteObjectToJson(RouteObject instance) =>
    <String, dynamic>{
      'geometry': instance.geometry,
      'legs': instance.legs,
      'distance': instance.distance,
      'duration': instance.duration,
    };

Leg _$LegFromJson(Map<String, dynamic> json) => Leg(
  steps: (json['steps'] as List<dynamic>)
      .map((e) => Step.fromJson(e as Map<String, dynamic>))
      .toList(),
  distance: (json['distance'] as num).toDouble(),
  duration: (json['duration'] as num).toDouble(),
);

Map<String, dynamic> _$LegToJson(Leg instance) => <String, dynamic>{
  'steps': instance.steps,
  'distance': instance.distance,
  'duration': instance.duration,
};

Step _$StepFromJson(Map<String, dynamic> json) => Step(
  geometry: json['geometry'],
  distance: (json['distance'] as num).toDouble(),
  duration: (json['duration'] as num).toDouble(),
  name: json['name'] as String?,
  maneuver: json['maneuver'] == null
      ? null
      : Maneuver.fromJson(json['maneuver'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StepToJson(Step instance) => <String, dynamic>{
  'geometry': instance.geometry,
  'distance': instance.distance,
  'duration': instance.duration,
  'name': instance.name,
  'maneuver': instance.maneuver,
};

Maneuver _$ManeuverFromJson(Map<String, dynamic> json) => Maneuver(
  instruction: json['instruction'] as String?,
  type: json['type'] as String?,
  modifier: json['modifier'] as String?,
);

Map<String, dynamic> _$ManeuverToJson(Maneuver instance) => <String, dynamic>{
  'instruction': instance.instruction,
  'type': instance.type,
  'modifier': instance.modifier,
};
