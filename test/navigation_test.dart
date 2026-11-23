import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';

void main() {
  Future<void> start(WidgetTester tester) => tester.pumpWidget(TripSyncApp());

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  testWidgets('back after Sign In does not return to Sign In', (tester) async {
    await start(tester);
    await tap(tester, 'Sign In');
    await systemBack(tester);
    expect(appBarTitle('My Trips'), findsOneWidget);
  });

  testWidgets('back after creating an account does not return to the forms', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'Register');
    await tap(tester, 'Create account');
    await systemBack(tester);
    expect(appBarTitle('My Trips'), findsOneWidget);
  });

  testWidgets('back after Sign Out does not return to My Trips', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'Sign In');
    await tap(tester, 'Sign Out');
    await systemBack(tester);
    expect(appBarTitle('My Trips'), findsNothing);
  });

  testWidgets('back from Register returns to Sign In', (tester) async {
    await start(tester);
    await tap(tester, 'Register');
    await systemBack(tester);
    expect(appBarTitle('Sign In'), findsOneWidget);
  });
}
