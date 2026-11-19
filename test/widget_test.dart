import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/routes.dart';

void main() {
  testWidgets('app starts on Sign In and can reach My Trips', (tester) async {
    await tester.pumpWidget(TripSyncApp(repository: InMemoryTripRepository()));

    expect(find.text('Sign In'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('My Trips'), findsWidgets);
  });

  for (final route in Routes.all) {
    testWidgets('route $route renders without errors', (tester) async {
      await tester.pumpWidget(
        TripSyncApp(repository: InMemoryTripRepository()),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route, arguments: 'trip1');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });
  }
}
