part of 'map_cubit.dart';

@immutable
sealed class MapState {}

final class MapInitial extends MapState {}

final class MapLoading extends MapState {}

final class MapFailure extends MapState {
  final String message;

  MapFailure(this.message);
}

final class MapLoaded extends MapState {
  final LatLng? destination;
  final List<LatLng> route;
  final bool showRoute;
  final bool isTracking;

  MapLoaded({
    this.destination,
    this.route = const [],
    this.showRoute = false,
    this.isTracking = false,
  });

  MapLoaded copyWith({
    LatLng? destination,
    List<LatLng>? route,
    bool? showRoute,
    bool? isTracking,
  }) {
    return MapLoaded(
      destination: destination ?? this.destination,
      route: route ?? this.route,
      showRoute: showRoute ?? this.showRoute,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

final class MapCrowdData extends MapState {
  final List<CrowdData> crowdData;
  MapCrowdData(this.crowdData);
}
