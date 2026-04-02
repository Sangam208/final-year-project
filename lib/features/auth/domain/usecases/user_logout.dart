import 'package:bus_tracker/core/errors/failure.dart';
import 'package:bus_tracker/core/usecase/usecase.dart';
import 'package:bus_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserLogout implements Usecase<void, NoParams> {
  final AuthRepository _authRepository;
  UserLogout(this._authRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _authRepository.logOut();
  }
}
