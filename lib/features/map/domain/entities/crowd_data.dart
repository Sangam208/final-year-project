class CrowdData {
  final int hour;
  final int dayOfWeek;
  final double distanceKm;
  final int routeId;
  final String crowdLevel;

  CrowdData({
    required this.hour,
    required this.dayOfWeek,
    required this.distanceKm,
    required this.routeId,
    required this.crowdLevel,
  });
}
