import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// Sign in / register / sign out. Get the user with
/// `context.read<AuthService>().currentUser`, don't hardcode ids.
abstract class AuthService extends ChangeNotifier {
  static const testUser = AppUser(
    id: 'u1',
    name: 'Test User',
    email: 'test@tripsync.app',
  );

  /// Null when signed out.
  AppUser? get signedInUser;

  bool get isSignedIn => signedInUser != null;

  /// Only call this on screens you can't reach without signing in.
  AppUser get currentUser {
    final user = signedInUser;
    if (user == null) {
      throw StateError('No user is signed in.');
    }
    return user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

/// Thrown by register / signIn. [message] is shown to the user as is.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  static const invalidEmail = AuthException('Enter a valid email address.');
  static const wrongCredentials = AuthException(
    'Email or password is incorrect.',
  );
  static const emailInUse = AuthException(
    'An account with this email already exists.',
  );
  static const weakPassword = AuthException(
    'Password must be at least 6 characters.',
  );
  static const noConnection = AuthException(
    'No internet connection. Try again.',
  );
  static const tooManyAttempts = AuthException(
    'Too many attempts. Wait a moment and try again.',
  );
  static const unknown = AuthException('Something went wrong. Try again.');

  @override
  String toString() => 'AuthException: $message';
}
