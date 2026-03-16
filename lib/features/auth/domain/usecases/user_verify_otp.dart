import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/core/usecase/usecase.dart';
import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:bus_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserVerifyOtp implements Usecase<User, UserVerifyParams> {
  final AuthRepository _authRepository;
  UserVerifyOtp(this._authRepository);

  @override
  Future<Either<Failure, User>> call(UserVerifyParams params) async {
    return await _authRepository.verifyOTP(
      phoneNumber: params.phoneNumber,
      token: params.token,
    );
  }
}

class UserVerifyParams {
  final String phoneNumber;
  final String token;

  UserVerifyParams({
    required this.phoneNumber,
    required this.token,
  });
}
