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

  void searchDestination(String query) async {
    if (query.trim().isEmpty) {
      emit(MapFailure('Please enter a destination.'));
      return;
    }
    emit(MapLoading());

    final res = await _mapRepository.getCoordinates(query: query);
    res.fold(
      (l) => emit(MapFailure(l.message)),
      (r) async {
        emit(MapLoaded(destination: r));
        await _getRoute(r);
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

    final res = await _mapRepository.getRoute(
      start: locationState.location!,
      end: destination,
    );
    res.fold(
      (l) => emit(MapFailure(l.message)),
      (r) => emit(
        MapLoaded(
          destination: destination,
          route: r.polylinePoints,
        ),
      ),
    );
  }

  void confirmRouteSelection(Map<String, dynamic> selectedBus) {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(showRoute: true, selectedBus: selectedBus));
    }
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

    // Take k nearest neighbors (let's start with k=5)
    const int k = 5;
    final nearest = distances.take(min(k, distances.length)).toList();

    // Count votes for each crowd level
    final Map<String, int> votes = {};
    for (var entry in nearest) {
      votes[entry.value] = (votes[entry.value] ?? 0) + 1;
    }

    // Return the crowd level with the most votes
    return votes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Helper: Euclidean distance between two points
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
