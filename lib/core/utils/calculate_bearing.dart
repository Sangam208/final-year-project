import 'dart:math';

import 'package:latlong2/latlong.dart';

// Adjust bus rotation during motion
double calculateBearing(LatLng start, LatLng end) {
  final lat1 = start.latitude * pi / 180;
  final lat2 = end.latitude * pi / 180;
  final dLon = (end.longitude - start.longitude) * pi / 180;

  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  return atan2(y, x);
}
