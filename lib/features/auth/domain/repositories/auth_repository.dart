import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, void>> sendOTP({
    required String phoneNumber,
  });

  Future<Either<Failure, User>> verifyOTP({
    required String phoneNumber,
    required String token,
  });

  Future<Either<Failure, User>> currentUser();
}
