import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/features/auth/view_models/auth_view_model.dart';

/// Sign in waits until [finish] is called, so we can check isLoading.
class _SlowAuth extends InMemoryAuthService {
  _SlowAuth() : super.signedOut();

  final _done = Completer<void>();
  void finish() => _done.complete();

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _done.future;
    return super.signIn(email: email, password: password);
  }
}

class _BrokenAuth extends InMemoryAuthService {
  _BrokenAuth() : super.signedOut();

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw Exception('boom');
}

void main() {
  late InMemoryAuthService auth;
  late AuthViewModel vm;

  setUp(() {
    auth = InMemoryAuthService.signedOut();
    vm = AuthViewModel(auth: auth);
  });

  group('validation', () {
    test('email', () {
      expect(AuthViewModel.validateEmail(''), 'Enter your email.');
      expect(
        AuthViewModel.validateEmail('ben'),
        'Enter a valid email address.',
      );
      expect(AuthViewModel.validateEmail('ben@x'), isNotNull);
      expect(AuthViewModel.validateEmail(' ben@example.com '), isNull);
    });

    test('password needs 6 characters', () {
      expect(AuthViewModel.validatePassword('12345'), isNotNull);
      expect(AuthViewModel.validatePassword('123456'), isNull);
    });

    test('name', () {
      expect(AuthViewModel.validateName('  '), 'Enter your name.');
      expect(AuthViewModel.validateName('Ben'), isNull);
    });
  });

  group('signIn', () {
    test('signs in with the right password', () async {
      final ok = await vm.signIn(
        email: AuthService.testUser.email,
        password: InMemoryAuthService.testPassword,
      );
      expect(ok, isTrue);
      expect(vm.error, isNull);
      expect(auth.currentUser.id, AuthService.testUser.id);
    });

    test('wrong password shows an error and stays signed out', () async {
      final ok = await vm.signIn(
        email: AuthService.testUser.email,
        password: 'wrong-password',
      );
      expect(ok, isFalse);
      expect(vm.error, 'Email or password is incorrect.');
      expect(auth.isSignedIn, isFalse);
    });

    test('empty password is caught before calling auth', () async {
      final ok = await vm.signIn(
        email: AuthService.testUser.email,
        password: '',
      );
      expect(ok, isFalse);
      expect(vm.error, 'Enter your password.');
    });

    test('isLoading is true while signing in', () async {
      final slow = _SlowAuth();
      final slowVm = AuthViewModel(auth: slow);
      final result = slowVm.signIn(
        email: AuthService.testUser.email,
        password: InMemoryAuthService.testPassword,
      );
      expect(slowVm.isLoading, isTrue);
      slow.finish();
      expect(await result, isTrue);
      expect(slowVm.isLoading, isFalse);
    });

    test('unexpected errors show a generic message', () async {
      final brokenVm = AuthViewModel(auth: _BrokenAuth());
      final ok = await brokenVm.signIn(
        email: AuthService.testUser.email,
        password: InMemoryAuthService.testPassword,
      );
      expect(ok, isFalse);
      expect(brokenVm.error, AuthException.unknown.message);
    });
  });

  group('register', () {
    test('creates the account and signs in with the name', () async {
      final ok = await vm.register(
        name: ' Ben ',
        email: 'Ben@Example.com',
        password: 'secret123',
      );
      expect(ok, isTrue);
      expect(auth.currentUser.name, 'Ben');
      expect(auth.currentUser.email, 'ben@example.com');
    });

    test('email already used shows an error', () async {
      final ok = await vm.register(
        name: 'Copy',
        email: AuthService.testUser.email,
        password: 'secret123',
      );
      expect(ok, isFalse);
      expect(vm.error, 'An account with this email already exists.');
    });

    test('short password is caught before calling auth', () async {
      final ok = await vm.register(
        name: 'Ben',
        email: 'ben@example.com',
        password: '123',
      );
      expect(ok, isFalse);
      expect(vm.error, 'Password must be at least 6 characters.');
      expect(auth.isSignedIn, isFalse);
    });
  });

  test('clearError removes the message', () async {
    await vm.signIn(email: '', password: '');
    expect(vm.error, isNotNull);
    vm.clearError();
    expect(vm.error, isNull);
  });

  test('can sign in again after signing out', () async {
    await vm.signIn(
      email: AuthService.testUser.email,
      password: InMemoryAuthService.testPassword,
    );
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    expect(() => auth.currentUser, throwsStateError);
  });
}
