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
  Future<RouteModel?> getRoute({required LatLng start, required LatLng end});
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

      if (response.statusCode == 200) {
        final coordinatesData = List<Map<String, dynamic>>.from(response.data);

        // Extract latitude and longitude from response
        final lat = double.parse(coordinatesData[0]['lat']);
        final lon = double.parse(coordinatesData[0]['lon']);

        return LatLng(lat, lon);
      }
      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RouteModel?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final response = await _dio.get(
        "http://router.project-osrm.org/route/v1/driving/"
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}?overview=full&geometries=polyline',
      );

      if (response.statusCode == 200) {
        final geometryData = Map<String, dynamic>.from(response.data);

        final encodedPolyline = geometryData['routes'][0]['geometry'] as String;
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
          encodedPolyline,
        );

        final route = decodedPoints
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList();
        return RouteModel(start: start, end: end, polylinePoints: route);
      }
      return null;
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
