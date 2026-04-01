import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/features/map/domain/entities/crowd_data.dart';
import 'package:bus_tracker/features/map/domain/entities/route_entity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:latlong2/latlong.dart';

abstract interface class MapRepository {
  Future<Either<Failure, LatLng>> getCoordinates({
    required String query,
  });
  Future<Either<Failure, RouteEntity>> getRoute({
    required LatLng start,
    required LatLng end,
  });
  Future<Either<Failure, List<CrowdData>?>> loadCrowdData();
}
