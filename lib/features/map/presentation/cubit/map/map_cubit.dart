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

  void confirmRouteSelection() {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(showRoute: true));
    }
  }

  // Called when user taps a bus in the bottom sheet
  void startBusTracking() {
    final currentState = state;
    if (currentState is MapLoaded && currentState.route.isNotEmpty) {
      emit(currentState.copyWith(showRoute: true));
    }
  }
}
