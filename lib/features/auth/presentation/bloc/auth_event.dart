part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSendOTP extends AuthEvent {
  final String phoneNumber;
  AuthSendOTP(this.phoneNumber);
}

final class AuthVerifyOTP extends AuthEvent {
  final String phoneNumber;
  final String token;

  AuthVerifyOTP(this.phoneNumber, this.token);
}

final class AuthCurrentUser extends AuthEvent {}

final class AuthLogOut extends AuthEvent {}
