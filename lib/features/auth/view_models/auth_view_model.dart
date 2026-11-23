import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';

/// State for the Sign In and Register screens (Story 1).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._auth});

  final AuthService _auth;

  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  bool get isLoading => _isLoading;

  /// Message to show under the form, or null.
  String? get error => _error;

  /// Returns true if signed in, so the screen can move on.
  Future<bool> signIn({required String email, required String password}) {
    final problem =
        validateEmail(email) ??
        (password.isEmpty ? 'Enter your password.' : null);
    return _submit(
      problem,
      () => _auth.signIn(email: email, password: password),
    );
  }

  /// Returns true if the account was created (and signed in).
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    final problem =
        validateName(name) ??
        validateEmail(email) ??
        validatePassword(password);
    return _submit(
      problem,
      () => _auth.register(name: name, email: email, password: password),
    );
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  // static so the form fields can use them too
  static String? validateName(String name) =>
      name.trim().isEmpty ? 'Enter your name.' : null;

  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Enter your email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  // 6 is Firebase's minimum
  static String? validatePassword(String password) =>
      password.length < 6 ? 'Password must be at least 6 characters.' : null;

  Future<bool> _submit(String? problem, Future<void> Function() call) async {
    if (problem != null) {
      _error = problem;
      _notify();
      return false;
    }
    _error = null;
    _isLoading = true;
    _notify();
    try {
      await call();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = AuthException.unknown.message;
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // the screen can close while sign in is still running
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
