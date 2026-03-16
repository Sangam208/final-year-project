import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/core/usecase/usecase.dart';
import 'package:bus_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserSendOTP implements Usecase<void, UserSendParams> {
  final AuthRepository _authRepository;
  UserSendOTP(this._authRepository);

  @override
  Future<Either<Failure, void>> call(UserSendParams params) async {
    return await _authRepository.sendOTP(phoneNumber: params.phoneNumber);
  }
}

class UserSendParams {
  final String phoneNumber;
  UserSendParams({
    required this.phoneNumber,
  });
}
