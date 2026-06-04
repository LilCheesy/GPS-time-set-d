import 'package:frontflutter/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:frontflutter/features/sos/data/models/sos_request.dart';
import 'package:frontflutter/features/sos/data/models/sos_response.dart';
import 'package:frontflutter/features/sos/data/models/trackasia_route.dart';
import 'package:frontflutter/features/sos/domain/repositories/sos_repository.dart';

class SosRepositoryImpl implements SosRepository {
  final SosRemoteDatasource _remoteDatasource;

  SosRepositoryImpl(this._remoteDatasource);

  @override
  Future<SosResponse> sendSos(SosRequest request) {
    return _remoteDatasource.sendSos(request);
  }

  @override
  Future<TrackAsiaRoute> getRoute({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
  }) {
    return _remoteDatasource.getRoute(
      userLat: userLat,
      userLng: userLng,
      destLat: destLat,
      destLng: destLng,
    );
  }
}
