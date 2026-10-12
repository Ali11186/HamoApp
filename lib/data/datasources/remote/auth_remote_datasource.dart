import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';
import '../../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Stream<UserEntity?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithPhoneAndPassword(
      String phoneNumber, String password);
  Future<UserModel> registerWithPhoneAndPassword({
    required String fullName,
    required String phoneNumber,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> updateFcmToken(String token);
  Future<void> deleteAccount();
  Future<UserModel> reloadUser();
}

/// Normalizes a phone number into a stable identifier usable both as a
/// Firestore lookup key and as the local-part of the internal Firebase Auth
/// email we generate under the hood (users never see this email).
String normalizePhoneNumber(String raw) {
  var clean = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
  if (clean.startsWith('+20')) clean = clean.substring(3);
  if (clean.startsWith('20') && clean.length > 10) clean = clean.substring(2);
  if (!clean.startsWith('0')) clean = '0$clean';
  return clean;
}

String _internalEmailForPhone(String normalizedPhone) {
  return '$normalizedPhone@aliapp.local';
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final ref =
          _firestore.collection(AppConstants.usersCollection).doc(user.uid);
      // The profile doc may not exist yet for a split second right after
      // registration (Auth fires before the Firestore write). Retry briefly.
      for (var i = 0; i < 5; i++) {
        try {
          final doc = await ref.get();
          if (doc.exists) return UserModel.fromFirestore(doc);
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 400));
      }
      // Fallback so we never bounce a signed-in user back to login.
      return UserModel(
        id: user.uid,
        fullName: user.displayName ?? '',
        email: '',
        phoneNumber: (user.email ?? '').split('@').first,
        role: UserRole.buyer,
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(
          message: e.message ?? 'Failed to get user', code: e.code);
    }
  }

  @override
  Future<UserModel> signInWithPhoneAndPassword(
    String phoneNumber,
    String password,
  ) async {
    try {
      final normalized = normalizePhoneNumber(phoneNumber);
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _internalEmailForPhone(normalized),
        password: password,
      );
      final user = credential.user!;
      final ref =
          _firestore.collection(AppConstants.usersCollection).doc(user.uid);
      final doc = await ref.get();
      if (doc.exists) return UserModel.fromFirestore(doc);

      // Auth account exists but profile doc is missing (e.g. created via a
      // script or a failed earlier attempt) -> recreate it.
      final model = UserModel(
        id: user.uid,
        fullName: user.displayName ?? normalized,
        email: '',
        phoneNumber: normalized,
        role: UserRole.buyer,
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: DateTime.now(),
      );
      await ref.set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapPhoneAuthError(e.code),
        code: e.code,
      );
    } on FirebaseException catch (e) {
      throw AuthException(message: _mapFirestoreError(e), code: e.code);
    }
  }

  @override
  Future<UserModel> registerWithPhoneAndPassword({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final normalized = normalizePhoneNumber(phoneNumber);

      // Duplicate phone numbers are rejected by Firebase Auth itself
      // ('email-already-in-use'), so no unauthenticated Firestore query is needed.
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _internalEmailForPhone(normalized),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName);

      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: '',
        phoneNumber: normalized,
        role: UserRole.buyer,
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: now,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapPhoneAuthError(e.code),
        code: e.code,
      );
    } on FirebaseException catch (e) {
      // Profile write failed: roll back the Auth account so the user can retry.
      try {
        await _firebaseAuth.currentUser?.delete();
      } catch (_) {}
      throw AuthException(message: _mapFirestoreError(e), code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: 'Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapPhoneAuthError(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    // No-op: phone/password accounts don't use email verification.
  }

  @override
  Future<void> updateFcmToken(String token) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .delete();
      }
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Failed to delete account');
    }
  }

  @override
  Future<UserModel> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return (await getCurrentUser())!;
    } catch (e) {
      throw ServerException(message: 'Failed to reload user');
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'صلاحيات Firestore غير مضبوطة. انشر ملف firestore.rules على مشروعك.';
    }
    if (e.code == 'unavailable') return 'تحقق من اتصال الإنترنت.';
    return 'حدث خطأ في قاعدة البيانات (${e.code}).';
  }

  String _mapPhoneAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'رقم الهاتف أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'رقم الهاتف مسجل بالفعل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا (8 أحرف على الأقل).';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى لاحقًا.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      default:
        return 'حدث خطأ، حاول مرة أخرى.';
    }
  }
}
