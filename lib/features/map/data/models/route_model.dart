import 'package:bus_tracker/features/map/domain/entities/route_entity.dart';

class RouteModel extends RouteEntity {
  RouteModel({
    required super.start,
    required super.end,
    required super.polylinePoints,
  });
}
