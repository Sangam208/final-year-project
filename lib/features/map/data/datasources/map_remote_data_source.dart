import 'package:bus_tracker/core/config/secrets.dart';
import 'package:bus_tracker/core/errors/exception.dart';
import 'package:bus_tracker/features/map/data/models/crowd_data_model.dart';
import 'package:bus_tracker/features/map/data/models/route_model.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

abstract interface class MapRemoteDataSource {
  Future<LatLng?> getCoordinates({required String query});

  Future<List<RouteModel>> getRoutes({
    required List<LatLng> waypoints,
  });
  Future<List<CrowdDataModel>?> loadCrowdData();
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final Dio _dio;
  MapRemoteDataSourceImpl(this._dio) {
    _dio.options.headers['User-Agent'] =
        'BusTrackerApp/1.0 (Flutter) - Academic Project - sangam.dhital72@gmail.com';
  }

  @override
  Future<LatLng?> getCoordinates({
    required String query,
  }) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '1',
          'countrycodes': 'np',
          'viewbox': '85.25,27.65,85.40,27.75', // Kathmandu bounding box
          'bounded': '1',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch location');
      }

      if (response.statusCode == 200) {
        final coordinatesData = List<Map<String, dynamic>>.from(response.data);

        if (coordinatesData.isEmpty) {
          throw ServerException("Location not found");
        }

        // Extract latitude and longitude from response
        final lat = double.parse(coordinatesData[0]['lat']);
        final lon = double.parse(coordinatesData[0]['lon']);

        return LatLng(lat, lon);
      }
      return null;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RouteModel>> getRoutes({
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.length < 2) return [];

    try {
      final bool supportsAlternatives = waypoints.length == 2;

      final Map<String, dynamic> requestBody = {
        'coordinates': waypoints.map((p) => [p.longitude, p.latitude]).toList(),
        'geometry': true,
        'instructions': false,
      };

      if (supportsAlternatives) {
        requestBody['alternative_routes'] = {
          'target_count': 2, // ask for 2 alternatives (total up to 3 routes)
          'weight_factor': 1.6,
          'share_factor': 0.7,
        };
      }

      final response = await _dio.post(
        'https://api.heigit.org/openrouteservice/v2/directions/driving-car/json',
        options: Options(
          headers: {
            'Authorization': orsApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routesData = data['routes'] as List;

        final List<RouteModel> routes = [];

        for (final routeJson in routesData) {
          final encoded = routeJson['geometry'] as String;
          final decoded = PolylinePoints().decodePolyline(encoded);
          final points = decoded
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          routes.add(
            RouteModel(
              start: waypoints.first,
              end: waypoints.last,
              polylinePoints: points,
            ),
          );
        }

        return routes;
      }
      return [];
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CrowdDataModel>?> loadCrowdData() async {
    try {
      // Loading CSV string
      final String csvString = await rootBundle.loadString(
        'assets/data/crowd_data.csv',
      );

      if (csvString.isEmpty) return null;

      // Converting Csv string to list of rows
      final List<List<dynamic>> csvTable = csv.decode(csvString);

      // Skip header row
      final dataRows = csvTable.skip(1).toList();

      return dataRows.map((row) => CrowdDataModel.fromCsvRow(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
