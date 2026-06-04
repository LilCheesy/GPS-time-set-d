import 'package:frontflutter/features/sos/data/models/sos_multi_response.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';

abstract class SosRepository {
  Future<SosResponse> sendSos(SosRequest request);
  Future<SosMultiResponse> scanFacilities(SosRequest request);
  Future<TrackAsiaRoute> getRoute({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
  });
}
