import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/routes.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('signed out: app starts on Sign In and can reach My Trips', (
    tester,
  ) async {
    await tester.pumpWidget(TripSyncApp(auth: InMemoryAuthService.signedOut()));

    expect(find.text('Sign In'), findsWidgets);

    await signInAsTestUser(tester);

    expect(find.text('My Trips'), findsWidgets);
  });

  testWidgets('signed in: app starts on My Trips', (tester) async {
    await tester.pumpWidget(TripSyncApp());
    await tester.pumpAndSettle();
    expect(find.text('My Trips'), findsWidgets);
  });

  for (final route in Routes.all) {
    testWidgets('route $route renders without errors', (tester) async {
      await tester.pumpWidget(TripSyncApp());
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route, arguments: 'trip1');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });
  }
}
