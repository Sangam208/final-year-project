import 'package:bus_tracker/features/map/domain/entities/crowd_data.dart';

class CrowdDataModel extends CrowdData {
  CrowdDataModel({
    required super.hour,
    required super.dayOfWeek,
    required super.distanceKm,
    required super.routeId,
    required super.crowdLevel,
  });

  // For CSV parsing
  factory CrowdDataModel.fromCsvRow(List<dynamic> row) {
    return CrowdDataModel(
      hour: int.tryParse(row[0].toString()) ?? 0,
      dayOfWeek: int.tryParse(row[1].toString()) ?? 1,
      distanceKm: double.tryParse(row[2].toString()) ?? 0.0,
      routeId: int.tryParse(row[3].toString()) ?? 1,
      crowdLevel: row[4].toString(),
    );
  }
}
