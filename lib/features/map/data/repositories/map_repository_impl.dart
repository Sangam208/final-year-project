import 'package:bus_tracker/core/errors/exception.dart';
import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/core/network/connection_checker.dart';
import 'package:bus_tracker/features/map/data/datasources/map_remote_data_source.dart';
import 'package:bus_tracker/features/map/data/models/crowd_data_model.dart';
import 'package:bus_tracker/features/map/domain/entities/route_entity.dart';
import 'package:bus_tracker/features/map/domain/repositories/map_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:latlong2/latlong.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _mapRemoteDataSource;
  final ConnectionChecker _connectionChecker;
  MapRepositoryImpl(this._mapRemoteDataSource, this._connectionChecker);

  @override
  Future<Either<Failure, LatLng>> getCoordinates({
    required String query,
  }) async {
    try {
      if (!await _connectionChecker.isConnected) {
        return left(Failure("No Internet Connection"));
      }
      final res = await _mapRemoteDataSource.getCoordinates(query: query);
      if (res == null) return left(Failure('Location not found'));
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<RouteEntity>>> getRoutes({
    required List<LatLng> waypoints,
  }) async {
    try {
      if (!await _connectionChecker.isConnected) {
        return left(Failure("No Internet Connection"));
      }
      final res = await _mapRemoteDataSource.getRoutes(waypoints: waypoints);
      if (res.isEmpty) return left(Failure('Failed to fetch routes'));
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CrowdDataModel>?>> loadCrowdData() async {
    try {
      final res = await _mapRemoteDataSource.loadCrowdData();
      if (res == null) return left(Failure('No crowd data available'));
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
