import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' hide LocationAccuracy;

part 'user_location_state.dart';

class UserLocationCubit extends Cubit<UserLocationState> {
  final Location _location = Location();

  StreamSubscription<LocationData>? _nativeLocationSubscription;
  StreamSubscription<Position>? _webLocationSubscription;

  UserLocationCubit() : super(UserLocationInitial()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    emit(UserLocationLoading());

    try {
      if (kIsWeb) {
        await _initWebLocation();
        return;
      }

      if (!await _checkNativeLocationPermission()) return;

      _nativeLocationSubscription = _location.onLocationChanged.listen(
        (locationData) {
          if (locationData.latitude == null || locationData.longitude == null) {
            return;
          }

          emit(
            UserLocationLoaded(
              LatLng(locationData.latitude!, locationData.longitude!),
            ),
          );
        },
      );
    } catch (e) {
      emit(UserLocationFailure('Unable to get location: $e'));
    }
  }

  Future<void> _initWebLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      emit(
        UserLocationFailure(
          'Location Services are turned off on this device.',
        ),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      emit(UserLocationFailure('Location permission was denied.'));
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      emit(
        UserLocationFailure(
          'Location permission is permanently denied in the browser.',
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    emit(UserLocationLoaded(LatLng(position.latitude, position.longitude)));

    _webLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (updatedPosition) {
        emit(
          UserLocationLoaded(
            LatLng(updatedPosition.latitude, updatedPosition.longitude),
          ),
        );
      },
      onError: (error) {
        emit(UserLocationFailure('Location update failed: $error'));
      },
    );
  }

  Future<bool> _checkNativeLocationPermission() async {
    var serviceEnabled = await _location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();

      if (!serviceEnabled) {
        emit(UserLocationFailure('Location Services are turned off.'));
        return false;
      }
    }

    var permissionGranted = await _location.hasPermission();

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
  Future<void> close() async {
    await _nativeLocationSubscription?.cancel();
    await _webLocationSubscription?.cancel();
    return super.close();
  }
}