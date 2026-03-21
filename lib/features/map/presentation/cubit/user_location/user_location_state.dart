part of 'user_location_cubit.dart';

@immutable
sealed class UserLocationState {}

final class UserLocationInitial extends UserLocationState {}

final class UserLocationLoaded extends UserLocationState {
  final LatLng? location;
  UserLocationLoaded(this.location);
}

final class UserLocationFailure extends UserLocationState {
  final String message;
  UserLocationFailure(this.message);
}

final class UserLocationLoading extends UserLocationState {}
