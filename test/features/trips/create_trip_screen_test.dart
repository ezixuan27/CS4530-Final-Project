import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/data/repositories.dart';
import 'package:final_project/models/trip.dart';

import '../../test_helpers.dart';

void main() {
  late InMemoryTripRepository trips;

  // signed in by default, so this starts on My Trips
  Future<void> openCreateTrip(WidgetTester tester) async {
    trips = InMemoryTripRepository();
    await tester.pumpWidget(
      TripSyncApp(repositories: Repositories(trips: trips)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create Trip'));
    await tester.pumpAndSettle();
  }

  // opens the picker and hits OK, which keeps the date it opened on
  Future<void> pickDate(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(OutlinedButton, label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(field('Trip name'), 'Italy Getaway');
    await tester.enterText(field('Destination'), 'Rome');
    await pickDate(tester, 'Start date');
    await pickDate(tester, 'End date');
  }

  Future<void> tapCreate(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Create trip'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty form shows field errors', (tester) async {
    await openCreateTrip(tester);
    await tapCreate(tester);
    expect(find.text('Enter a trip name.'), findsOneWidget);
    expect(find.text('Enter a destination.'), findsOneWidget);
    expect(await trips.tripsForUser(AuthService.testUser.id), isEmpty);
  });

  testWidgets('no dates picked shows an error', (tester) async {
    await openCreateTrip(tester);
    await tester.enterText(field('Trip name'), 'Italy Getaway');
    await tester.enterText(field('Destination'), 'Rome');
    await tapCreate(tester);
    expect(find.text('Pick a start date.'), findsOneWidget);
  });

  testWidgets('creating shows the invite code and I am organizer', (
    tester,
  ) async {
    await openCreateTrip(tester);
    await fillForm(tester);
    await tapCreate(tester);

    final saved = await trips.tripsForUser(AuthService.testUser.id);
    expect(saved, hasLength(1));
    expect(saved.single.roleOf(AuthService.testUser.id), TripRole.organizer);
    expect(find.text('Trip created'), findsOneWidget);
    expect(find.text(saved.single.inviteCode), findsOneWidget);
  });

  testWidgets('copy button puts the code on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await openCreateTrip(tester);
    await fillForm(tester);
    await tapCreate(tester);
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();

    final code = (await trips.tripsForUser(AuthService.testUser.id))
        .single
        .inviteCode;
    expect(copied, code);
    expect(find.text('Code copied'), findsOneWidget);
  });

  testWidgets('Done goes back to My Trips with the new trip', (tester) async {
    await openCreateTrip(tester);
    await fillForm(tester);
    await tapCreate(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();

    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Italy Getaway'), findsOneWidget);
  });
}
