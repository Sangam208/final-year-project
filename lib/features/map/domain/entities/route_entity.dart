import 'package:latlong2/latlong.dart';

class RouteEntity {
  final LatLng start;
  final LatLng end;
  final List<LatLng> polylinePoints;
  RouteEntity({
    required this.start,
    required this.end,
    required this.polylinePoints,
  });
}
