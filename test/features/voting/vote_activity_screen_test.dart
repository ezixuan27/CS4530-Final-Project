import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/app.dart';
import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/data/repositories.dart';
import 'package:final_project/features/voting/data/in_memory_poll_repository.dart';
import 'package:final_project/models/activity_poll.dart';
import 'package:final_project/routes.dart';

void main() {
  late InMemoryTripRepository trips;
  late InMemoryPollRepository polls;

  setUp(() {
    trips = InMemoryTripRepository();
    polls = InMemoryPollRepository();
  });

  Future<String> seedTrip(String organizerId) async {
    final trip = await trips.createTrip(
      name: 'Rome',
      destination: 'Rome',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 7),
      organizerId: organizerId,
    );
    final me = AuthService.testUser.id;
    if (organizerId != me) await trips.joinTrip(trip.inviteCode, me);
    return trip.id;
  }

  Future<void> openPolls(WidgetTester tester, String tripId) async {
    await tester.pumpWidget(
      TripSyncApp(
        repositories: Repositories(trips: trips, polls: polls),
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(Routes.voteActivity, arguments: tripId);
    await tester.pumpAndSettle();
  }

  Future<void> createPoll(
    WidgetTester tester,
    String question,
    String options,
  ) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Question'),
      question,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Options (one per line)'),
      options,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
  }

  /// The vote count shown on [option]'s row.
  Finder countOn(String option, String count) => find.descendant(
    of: find.widgetWithText(ListTile, option),
    matching: find.text(count),
  );

  testWidgets('renders with no trip and no polls', (tester) async {
    await openPolls(tester, 'trip1');

    expect(find.text('No polls yet.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('organizer creates a poll and it appears', (tester) async {
    await openPolls(tester, await seedTrip(AuthService.testUser.id));
    await createPoll(
      tester,
      'Day 2 afternoon?',
      'Vatican Museums\nCooking class',
    );

    expect(find.text('Day 2 afternoon?'), findsOneWidget);
    expect(countOn('Vatican Museums', '0'), findsOneWidget);
    expect(countOn('Cooking class', '0'), findsOneWidget);
  });

  testWidgets('create dialog shows validation error', (tester) async {
    await openPolls(tester, await seedTrip(AuthService.testUser.id));
    await createPoll(tester, 'Q', 'Only one');

    expect(find.text('Add at least 2 options, one per line.'), findsOneWidget);
    expect(find.text('New poll'), findsOneWidget); // dialog still open
  });

  testWidgets('tapping an option votes and updates the count', (tester) async {
    await openPolls(tester, await seedTrip(AuthService.testUser.id));
    await createPoll(tester, 'Q', 'A\nB');

    await tester.tap(find.widgetWithText(ListTile, 'A'));
    await tester.pumpAndSettle();
    expect(countOn('A', '1'), findsOneWidget);
    expect(countOn('B', '0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'B'));
    await tester.pumpAndSettle();
    expect(countOn('A', '0'), findsOneWidget);
    expect(countOn('B', '1'), findsOneWidget);
  });

  testWidgets('members do not see the create button', (tester) async {
    await openPolls(tester, await seedTrip('u2'));

    expect(find.text('No polls yet.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  group('edit poll', () {
    final me = AuthService.testUser.id;

    /// Reads the poll from the repository. runAsync because the in-memory
    /// stream delivers events outside the widget test's fake clock.
    Future<ActivityPoll> stored(WidgetTester tester, String tripId) async =>
        (await tester.runAsync(() => polls.watchPolls(tripId).first))!.single;

    /// Seeds a poll with options A, B and my vote on A, then opens the screen.
    Future<String> openWithPoll(WidgetTester tester, String organizerId) async {
      final tripId = await seedTrip(organizerId);
      await polls.createPoll(
        tripId: tripId,
        question: 'Q',
        options: const ['A', 'B'],
        createdBy: organizerId,
      );
      final poll = await stored(tester, tripId);
      await polls.vote(
        tripId: tripId,
        pollId: poll.id,
        userId: me,
        option: 'A',
      );
      await openPolls(tester, tripId);
      return tripId;
    }

    Future<void> openEditor(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Edit poll'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('members do not see the edit button', (tester) async {
      await openWithPoll(tester, 'u2');

      expect(find.text('Q'), findsOneWidget);
      expect(find.byTooltip('Edit poll'), findsNothing);
    });

    testWidgets('organizer renames an option and its votes stay', (
      tester,
    ) async {
      final tripId = await openWithPoll(tester, me);
      await openEditor(tester);
      expect(find.text('Edit poll'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'A+');
      await save(tester);

      expect(find.text('Edit poll'), findsNothing);
      expect(countOn('A+', '1'), findsOneWidget);
      final poll = await stored(tester, tripId);
      expect(poll.voteOf(me), 'A+');
    });

    testWidgets('organizer removes the voted option and adds one', (
      tester,
    ) async {
      final tripId = await openWithPoll(tester, me);
      await openEditor(tester);

      await tester.tap(find.byTooltip('Remove option').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add option'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'C');
      await save(tester);

      expect(find.widgetWithText(ListTile, 'A'), findsNothing);
      expect(countOn('B', '0'), findsOneWidget);
      expect(countOn('C', '0'), findsOneWidget);
      final poll = await stored(tester, tripId);
      expect(poll.options, ['B', 'C']);
      expect(poll.votes, isEmpty);
    });

    testWidgets('edit dialog shows validation error', (tester) async {
      await openWithPoll(tester, me);
      await openEditor(tester);

      await tester.tap(find.byTooltip('Remove option').first);
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.text('Add at least 2 options.'), findsOneWidget);
      expect(find.text('Edit poll'), findsOneWidget);
    });
  });
}
