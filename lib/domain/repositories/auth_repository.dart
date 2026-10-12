import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of the currently authenticated user
  Stream<UserEntity?> get authStateChanges;

  /// Get the currently authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Sign in with phone number and password
  Future<Either<Failure, UserEntity>> signInWithPhoneAndPassword({
    required String phoneNumber,
    required String password,
  });

  /// Register with full name, phone number and password
  Future<Either<Failure, UserEntity>> registerWithPhoneAndPassword({
    required String fullName,
    required String phoneNumber,
    required String password,
  });

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Update FCM token
  Future<Either<Failure, void>> updateFcmToken(String token);

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();

  /// Reload user
  Future<Either<Failure, UserEntity>> reloadUser();
}
