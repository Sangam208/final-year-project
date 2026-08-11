import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

part 'user_location_state.dart';

class UserLocationCubit extends Cubit<UserLocationState> {
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  UserLocationCubit() : super(UserLocationInitial()) {
    _initLocation();
    _listenToServiceStatus();
  }

  void _listenToServiceStatus() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        if (status == ServiceStatus.enabled) {
          _initLocation();
        } else if (status == ServiceStatus.disabled) {
          emit(UserLocationFailure('Location service disabled'));
        }
      },
    );
  }

  Future<void> _initLocation() async {
    emit(UserLocationLoading());
    try {
      final hasPermission = await _checkRequestPermission();
      if (!hasPermission) {
        emit(UserLocationFailure('Location permission denied'));
        return;
      }

      // Get current position first
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      emit(UserLocationLoaded(LatLng(position.latitude, position.longitude)));

      // Listen to location changes
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          emit(
            UserLocationLoaded(LatLng(position.latitude, position.longitude)),
          );
        },
        onError: (_) => emit(UserLocationFailure("Location disabled")),
        cancelOnError: true,
      );
    } catch (e) {
      emit(UserLocationFailure(e.toString()));
    }
  }

  Future<bool> _checkRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  Future<void> close() {
    _serviceStatusSubscription?.cancel();
    return super.close();
  }
}
