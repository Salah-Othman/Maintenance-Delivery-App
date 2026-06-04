import 'package:firebase_auth/firebase_auth.dart';
import 'package:delivery_app/core/errors/failures.dart';

class FirebaseExceptionHandler {
  static Failure handle(Object e) {
    if (e is FirebaseAuthException) {
      return _handleAuthException(e);
    }
    if (e is FirebaseException) {
      return _handleFirebaseException(e);
    }
    if (e is FormatException) {
      return const ValidationFailure('Invalid data format');
    }
    return UnknownFailure(e.toString());
  }

  static Failure _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return const AuthFailure('Invalid email or password');
      case 'email-already-in-use':
        return const AuthFailure('This email is already registered');
      case 'weak-password':
        return const AuthFailure('Password is too weak. Use at least 6 characters');
      case 'invalid-email':
        return const AuthFailure('Invalid email address');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later');
      case 'operation-not-allowed':
        return const AuthFailure('Email/password sign-in is not enabled');
      case 'requires-recent-login':
        return const AuthFailure('Please sign in again to continue');
      default:
        return AuthFailure(e.message ?? 'Authentication error');
    }
  }

  static Failure _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionFailure('You don\'t have permission to perform this action');
      case 'unavailable':
      case 'network-request-failed':
        return const NetworkFailure();
      case 'not-found':
        return const NotFoundFailure('The requested resource was not found');
      case 'already-exists':
        return const ServerFailure('This resource already exists');
      case 'resource-exhausted':
        return const ServerFailure('Quota exceeded. Please try again later');
      case 'cancelled':
        return const ServerFailure('Operation was cancelled');
      case 'deadline-exceeded':
        return const NetworkFailure('Request timed out. Please try again');
      case 'aborted':
        return const ServerFailure('Operation was aborted');
      case 'failed-precondition':
        return const ServerFailure('Operation failed. Please try again');
      case 'out-of-range':
        return const ValidationFailure('Invalid value provided');
      case 'unauthenticated':
        return const AuthFailure('Please sign in to continue');
      case 'internal':
        return const ServerFailure('Internal server error. Please try again later');
      default:
        return ServerFailure(e.message ?? 'An error occurred');
    }
  }
}
