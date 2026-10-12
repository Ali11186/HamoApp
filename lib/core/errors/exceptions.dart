class ServerException implements Exception {
  final String message;
  const ServerException({required this.message, this.code});
  final dynamic code;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}

class AuthException implements Exception {
  final String message;
  final dynamic code;
  const AuthException({required this.message, this.code});
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class StorageException implements Exception {
  final String message;
  const StorageException({required this.message});
}

class PaymentException implements Exception {
  final String message;
  const PaymentException({required this.message});
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException({required this.message});
}

class PermissionException implements Exception {
  final String message;
  const PermissionException({required this.message});
}

class FirebaseAuthExceptionMapper {
  static String mapErrorCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى لاحقًا';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'حدث خطأ أثناء تسجيل الدخول: $code';
    }
  }
}
