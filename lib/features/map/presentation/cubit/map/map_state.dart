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
  final List<LatLng> route; // the active route (after bus selection)
  final List<List<LatLng>> availableRoutes; // all routes from OSRM
  final bool showRoute;
  final bool isTracking;
  final Map<String, dynamic>? selectedBus;
  final int userLocationIndex; // index in `route` where the user actually is

  MapLoaded({
    this.destination,
    this.route = const [],
    this.availableRoutes = const [],
    this.showRoute = false,
    this.isTracking = false,
    this.selectedBus,
    this.userLocationIndex = 0,
  });

  MapLoaded copyWith({
    LatLng? destination,
    List<LatLng>? route,
    List<List<LatLng>>? availableRoutes,
    bool? showRoute,
    bool? isTracking,
    Map<String, dynamic>? selectedBus,
    int? userLocationIndex,
  }) {
    return MapLoaded(
      destination: destination ?? this.destination,
      route: route ?? this.route,
      availableRoutes: availableRoutes ?? this.availableRoutes,
      showRoute: showRoute ?? this.showRoute,
      isTracking: isTracking ?? this.isTracking,
      selectedBus: selectedBus ?? this.selectedBus,
      userLocationIndex: userLocationIndex ?? this.userLocationIndex,
    );
  }
}
