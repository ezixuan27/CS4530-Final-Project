import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';

import '../../test_helpers.dart';

void main() {
  late InMemoryAuthService auth;

  Future<void> start(WidgetTester tester) async {
    auth = InMemoryAuthService.signedOut();
    await tester.pumpWidget(TripSyncApp(auth: auth));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  group('Sign In', () {
    testWidgets('empty form shows field errors', (tester) async {
      await start(tester);
      await tapButton(tester, 'Sign In');
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('wrong password shows an error', (tester) async {
      await start(tester);
      await tester.enterText(field('Email'), AuthService.testUser.email);
      await tester.enterText(field('Password'), 'wrong-password');
      await tapButton(tester, 'Sign In');
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(appBarTitle('Sign In'), findsOneWidget);
    });

    testWidgets('error goes away when you start typing', (tester) async {
      await start(tester);
      await tester.enterText(field('Email'), AuthService.testUser.email);
      await tester.enterText(field('Password'), 'wrong-password');
      await tapButton(tester, 'Sign In');
      await tester.enterText(field('Password'), 'wrong-passwor');
      await tester.pump();
      expect(find.text('Email or password is incorrect.'), findsNothing);
    });

    testWidgets('right password opens My Trips', (tester) async {
      await start(tester);
      await signInAsTestUser(tester);
      expect(appBarTitle('My Trips'), findsOneWidget);
      expect(auth.currentUser.id, AuthService.testUser.id);
    });
  });

  group('Register', () {
    Future<void> fillRegister(
      WidgetTester tester, {
      String name = 'Ben',
      String email = 'ben@example.com',
      String password = 'secret123',
    }) async {
      await tapButton(tester, 'Register');
      await tester.enterText(field('Name'), name);
      await tester.enterText(field('Email'), email);
      await tester.enterText(field('Password'), password);
      await tapButton(tester, 'Create account');
    }

    testWidgets('creates an account and opens My Trips', (tester) async {
      await start(tester);
      await fillRegister(tester);
      expect(appBarTitle('My Trips'), findsOneWidget);
      expect(auth.currentUser.name, 'Ben');
    });

    testWidgets('short password shows a field error', (tester) async {
      await start(tester);
      await fillRegister(tester, password: '123');
      expect(
        find.text('Password must be at least 6 characters.'),
        findsOneWidget,
      );
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('email already used shows an error', (tester) async {
      await start(tester);
      await fillRegister(tester, email: AuthService.testUser.email);
      expect(
        find.text('An account with this email already exists.'),
        findsOneWidget,
      );
      expect(appBarTitle('Register'), findsOneWidget);
    });
  });

  testWidgets('Sign Out signs out and goes back to Sign In', (tester) async {
    await start(tester);
    await signInAsTestUser(tester);
    await tapButton(tester, 'Sign Out');
    expect(appBarTitle('Sign In'), findsOneWidget);
    expect(auth.isSignedIn, isFalse);
  });
}
