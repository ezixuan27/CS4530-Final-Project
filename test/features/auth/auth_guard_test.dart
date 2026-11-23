import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/routes.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    InMemoryAuthService auth,
    String route,
  ) async {
    await tester.pumpWidget(TripSyncApp(auth: auth));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(route, arguments: 'trip1');
    await tester.pumpAndSettle();
  }

  String? topRouteName(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).last);
    return ModalRoute.of(context)?.settings.name;
  }

  group('signed out', () {
    for (final route in Routes.all.where((r) => !Routes.public.contains(r))) {
      testWidgets('$route shows Sign In instead', (tester) async {
        await open(tester, InMemoryAuthService.signedOut(), route);
        expect(topRouteName(tester), Routes.signIn);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Register is still reachable', (tester) async {
      await open(tester, InMemoryAuthService.signedOut(), Routes.register);
      expect(topRouteName(tester), Routes.register);
    });
  });

  testWidgets('signed in: trip screens open normally', (tester) async {
    await open(tester, InMemoryAuthService(), Routes.expenses);
    expect(topRouteName(tester), Routes.expenses);
  });
}
