import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';
import '../../entities/user_entity.dart';

class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String phoneNumber,
    required String password,
  }) {
    return _repository.signInWithPhoneAndPassword(
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) {
    return _repository.registerWithPhoneAndPassword(
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}

class SignOutUseCase {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.signOut();
  }
}

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  const ForgotPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserEntity?>> call() {
    return _repository.getCurrentUser();
  }
}
