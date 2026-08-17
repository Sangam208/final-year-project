import 'package:bus_tracker/core/errors/exception.dart';
import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/core/network/connection_checker.dart';
import 'package:bus_tracker/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:bus_tracker/features/auth/data/models/user_model.dart';
import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:bus_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final ConnectionChecker _connectionChecker;
  AuthRepositoryImpl(this._authRemoteDataSource, this._connectionChecker);

  @override
  Future<Either<Failure, void>> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      if (!await _connectionChecker.isConnected) {
        return left(Failure("No Internet Connection"));
      }
      final res = await _authRemoteDataSource.sendOTP(phoneNumber: phoneNumber);
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOTP({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      if (!await _connectionChecker.isConnected) {
        return left(Failure("No Internet Connection"));
      }
      final res = await _authRemoteDataSource.verifyOTP(
        phoneNumber: phoneNumber,
        token: token,
      );
      return right(res);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> currentUser() async {
    try {
      if (!await _connectionChecker.isConnected) {
        final session = _authRemoteDataSource.currentUserSession;
        if (session == null) {
          return left(Failure("User not logged in"));
        }
        return right(
          UserModel(
            id: session.user.id,
            phoneNumber: session.user.phone ?? '',
          ),
        );
      }
      final user = await _authRemoteDataSource.getCurrentUserData();
      if (user == null) return left(Failure(''));
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      if (!await _connectionChecker.isConnected) {
        return left(Failure("No Internet Connection"));
      }
      await _authRemoteDataSource.logout();
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
