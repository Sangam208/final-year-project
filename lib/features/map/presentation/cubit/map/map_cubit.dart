import 'dart:math';

import 'package:bus_tracker/features/map/domain/entities/crowd_data.dart';
import 'package:bus_tracker/features/map/domain/repositories/map_repository.dart';
import 'package:bus_tracker/features/map/presentation/cubit/user_location/user_location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapRepository _mapRepository;
  final UserLocationCubit _userLocationCubit;

  MapCubit({
    required MapRepository mapRepository,
    required UserLocationCubit userLocationCubit,
  }) : _mapRepository = mapRepository,
       _userLocationCubit = userLocationCubit,
       super(MapInitial());

  Future<bool> searchDestination(String query) async {
    emit(MapLoading());

    final res = await _mapRepository.getCoordinates(query: query);
    return res.fold(
      (l) {
        emit(MapFailure(l.message));
        return false;
      },
      (r) async {
        emit(MapLoaded(destination: r));
        await _getRoute(r);
        return true;
      },
    );
  }

  Future<void> _getRoute(LatLng destination) async {
    final locationState = _userLocationCubit.state;
    if (locationState is! UserLocationLoaded ||
        locationState.location == null) {
      emit(MapFailure('Current location not available'));
      return;
    }

    emit(MapLoading());

    final res = await _mapRepository.getRoutes(
      waypoints: [locationState.location!, destination],
    );

    res.fold(
      (l) => emit(MapFailure(l.message)),
      (routes) {
        final available = routes.map((r) => r.polylinePoints).toList();

        emit(
          MapLoaded(
            destination: destination,
            availableRoutes: available,
          ),
        );
      },
    );
  }

  Future<void> confirmRouteSelection(Map<String, dynamic> selectedBus) async {
    final currentState = state;
    if (currentState is! MapLoaded) return;

    final locationState = _userLocationCubit.state;
    if (locationState is! UserLocationLoaded ||
        locationState.location == null) {
      emit(MapFailure('Current location not available'));
      return;
    }
    final userLocation = locationState.location!;
    final destination = currentState.destination;
    if (destination == null) return;

    final referenceRoute = currentState.availableRoutes.isNotEmpty
        ? currentState.availableRoutes.first
        : <LatLng>[];

    if (referenceRoute.length < 2) {
      emit(
        currentState.copyWith(
          showRoute: true,
          selectedBus: selectedBus,
          route: referenceRoute,
          userLocationIndex: 0,
        ),
      );
      return;
    }

    // Simulated "how far back is the bus"
    final approachDistanceMeters = switch (selectedBus['name']) {
      'Fast Bus' => 800.0,
      'Regular Bus' => 1600.0,
      'Economy Bus' => 2800.0,
      _ => 1200.0,
    };

    const distanceCalc = Distance();
    final backwardBearing = distanceCalc.bearing(
      referenceRoute[1],
      referenceRoute[0],
    );
    final busOrigin = distanceCalc.offset(
      userLocation,
      approachDistanceMeters,
      backwardBearing,
    );

    // Simulating bus movement: busOrigin -> userLocation -> destination.
    List<LatLng> fullRoute = [];
    try {
      final res = await _mapRepository.getRoutes(
        waypoints: [busOrigin, userLocation, destination],
      );
      res.fold(
        (l) => fullRoute = [],
        (routes) =>
            fullRoute = routes.isNotEmpty ? routes.first.polylinePoints : [],
      );
    } catch (_) {
      fullRoute = [];
    }

    if (fullRoute.length < 2) {
      // Fallback
      emit(
        currentState.copyWith(
          showRoute: true,
          selectedBus: selectedBus,
          route: referenceRoute,
          userLocationIndex: 0,
        ),
      );
      return;
    }

    final userIndex = _nearestIndex(fullRoute, userLocation);

    emit(
      currentState.copyWith(
        showRoute: true,
        selectedBus: selectedBus,
        route: fullRoute,
        userLocationIndex: userIndex,
      ),
    );
  }

  /// Finding nearest possible point to the user where bus stops
  int _nearestIndex(List<LatLng> route, LatLng point) {
    const distanceCalc = Distance();
    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < route.length; i++) {
      final d = distanceCalc(route[i], point);
      if (d < minDist) {
        minDist = d;
        nearest = i;
      }
    }
    return nearest;
  }

  void startBusTracking() {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(isTracking: true));
    }
  }

  void stopBusTracking() {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(
        currentState.copyWith(
          isTracking: false,
          showRoute: false,
          route: [],
          selectedBus: null,
          userLocationIndex: 0,
        ),
      );
    }
  }

  Future<void> loadCrowdData() async {
    final res = await _mapRepository.loadCrowdData();

    res.fold(
      (l) => emit(MapFailure(l.message)),
      (r) {
        if (r == null) return;
        crowdDataList = r;
      },
    );
  }

  List<CrowdData> crowdDataList = [];

  String predictCrowdLevel({
    required int hour,
    required int dayOfWeek,
    required double distanceKm,
    required int routeId,
  }) {
    if (crowdDataList.isEmpty) {
      return "Unavailable"; // fallback
    }

    // Calculate Euclidean distance for each historical data point
    final List<MapEntry<double, String>> distances = crowdDataList.map((data) {
      final dist = _euclideanDistance(
        hour1: hour,
        day1: dayOfWeek,
        dist1: distanceKm,
        route1: routeId,
        hour2: data.hour,
        day2: data.dayOfWeek,
        dist2: data.distanceKm,
        route2: data.routeId,
      );
      return MapEntry(dist, data.crowdLevel);
    }).toList();

    // Sort by distance (closest first)
    distances.sort((a, b) => a.key.compareTo(b.key));

    // Take k nearest neighbors (k=5)
    const int k = 5;
    final nearest = distances.take(k).toList();

    // Count votes for each crowd level
    final Map<String, int> votes = {};
    for (var entry in nearest) {
      votes[entry.value] = (votes[entry.value] ?? 0) + 1;
    }

    // Return the crowd level with the most votes
    return votes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Euclidean distance between two points
  double _euclideanDistance({
    required int hour1,
    required int day1,
    required double dist1,
    required int route1,
    required int hour2,
    required int day2,
    required double dist2,
    required int route2,
  }) {
    final dh = (hour1 - hour2).toDouble();
    final dd = (day1 - day2).toDouble();
    final ds = dist1 - dist2;
    final dr = (route1 - route2).toDouble();

    return sqrt(dh * dh + dd * dd + ds * ds + dr * dr);
  }
}
