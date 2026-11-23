import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import 'auth_service.dart';

/// The real AuthService. The name from Register is saved as the Firebase
/// display name, so we don't need a users collection yet.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    // userChanges (not authStateChanges) so we also hear when the name is set
    _subscription = _auth.userChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  @override
  AppUser? get signedInUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    final email = user.email ?? '';
    return AppUser(id: user.uid, name: user.displayName ?? email, email: email);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _run(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    await user.reload();
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _run(Future<void> Function() call) async {
    try {
      await call();
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e.code);
    }
  }

  static AuthException _toAuthException(String code) => switch (code) {
    'invalid-email' => AuthException.invalidEmail,
    // Firebase now sends invalid-credential for every bad login
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'wrong-password' ||
    'user-not-found' ||
    'user-disabled' => AuthException.wrongCredentials,
    'email-already-in-use' => AuthException.emailInUse,
    'weak-password' => AuthException.weakPassword,
    'network-request-failed' => AuthException.noConnection,
    'too-many-requests' => AuthException.tooManyAttempts,
    _ => AuthException.unknown,
  };

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
