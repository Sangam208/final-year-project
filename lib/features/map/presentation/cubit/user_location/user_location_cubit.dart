import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

part 'user_location_state.dart';

class UserLocationCubit extends Cubit<UserLocationState> {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  UserLocationCubit() : super(UserLocationInitial()) {
    _initLocation();
  }

  // initialize location when app starts
  Future<void> _initLocation() async {
    emit(UserLocationLoading());
    try {
      if (!await _checkRequestPermission()) return;

      // listen to location changes and update current location
      _locationSubscription = _location.onLocationChanged.listen(
        (LocationData locationData) {
          final currentPos = LatLng(
            locationData.latitude ?? 27.7172,
            locationData.longitude ?? 85.3240,
          );
          emit(UserLocationLoaded(currentPos));
        },
      );
    } catch (e) {
      emit(UserLocationFailure(e.toString()));
    }
  }

  // check if location is enabled and permission is granted
  Future<bool> _checkRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
    if (permissionGranted != PermissionStatus.granted &&
        permissionGranted != PermissionStatus.grantedLimited) {
      emit(UserLocationFailure('Location permission was not granted.'));
      return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
