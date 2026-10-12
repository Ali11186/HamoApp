import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Get user by ID
  Future<Either<Failure, UserEntity>> getUserById(String userId);

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    File? avatar,
    String? language,
    bool? notificationsEnabled,
    String? businessName,
    String? businessDescription,
    String? location,
  });

  /// Submit seller verification
  Future<Either<Failure, void>> submitSellerVerification({
    required String userId,
    required List<File> documents,
    required String businessName,
    required String businessDescription,
  });

  /// Get pending seller verifications (admin)
  Future<Either<Failure, List<UserEntity>>> getPendingVerifications();

  /// Approve/reject seller verification (admin)
  Future<Either<Failure, void>> updateVerificationStatus({
    required String userId,
    required VerificationStatus status,
    String? reason,
  });

  /// Toggle user active status (admin)
  Future<Either<Failure, void>> toggleUserActive(String userId, bool isActive);

  /// Change a user's role (admin only). Guarded server-side by
  /// firestore.rules so only an admin account can call this successfully.
  Future<Either<Failure, void>> setUserRole(String userId, UserRole role);

  /// Permanently delete a user's Firestore profile (admin).
  /// Does not delete their Firebase Auth account (requires Admin SDK).
  Future<Either<Failure, void>> deleteUserProfile(String userId);

  /// Get all users (admin)
  Future<Either<Failure, List<UserEntity>>> getAllUsers({
    String? role,
    int limit = 50,
    String? lastDocumentId,
  });

  /// Stream user profile changes
  Stream<UserEntity?> watchUser(String userId);

  /// Add/remove from wishlist
  Future<Either<Failure, void>> toggleWishlist(String userId, String productId);

  /// Get seller stats
  Future<Either<Failure, Map<String, dynamic>>> getSellerStats(String sellerId);
}
