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
  final Map<String, dynamic>? selectedBus;

  MapLoaded({
    this.destination,
    this.route = const [],
    this.showRoute = false,
    this.isTracking = false,
    this.selectedBus,
  });

  MapLoaded copyWith({
    LatLng? destination,
    List<LatLng>? route,
    bool? showRoute,
    bool? isTracking,
    Map<String, dynamic>? selectedBus,
  }) {
    return MapLoaded(
      destination: destination ?? this.destination,
      route: route ?? this.route,
      showRoute: showRoute ?? this.showRoute,
      isTracking: isTracking ?? this.isTracking,
      selectedBus: selectedBus ?? this.selectedBus,
    );
  }
}
