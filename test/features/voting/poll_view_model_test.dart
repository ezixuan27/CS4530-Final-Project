import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/features/voting/data/in_memory_poll_repository.dart';
import 'package:final_project/features/voting/view_models/poll_view_model.dart';

void main() {
  final me = AuthService.testUser.id; // 'u1'

  test('parseOptions trims and drops empty lines', () {
    expect(PollViewModel.parseOptions('Pizza\n\n Sushi '), ['Pizza', 'Sushi']);
  });

  group('PollViewModel', () {
    late InMemoryTripRepository trips;
    late InMemoryPollRepository polls;
    final vms = <PollViewModel>[];

    setUp(() {
      trips = InMemoryTripRepository();
      polls = InMemoryPollRepository();
    });

    tearDown(() {
      for (final vm in vms) {
        vm.dispose();
      }
      vms.clear();
    });

    Future<String> seedTrip({required String organizerId}) async {
      final trip = await trips.createTrip(
        name: 'Rome',
        destination: 'Rome',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 7),
        organizerId: organizerId,
      );
      if (organizerId != me) await trips.joinTrip(trip.inviteCode, me);
      return trip.id;
    }

    Future<PollViewModel> open(String tripId) async {
      final vm = PollViewModel(
        polls: polls,
        trips: trips,
        auth: AuthService(),
        tripId: tripId,
      );
      vms.add(vm);
      await Future<void>.delayed(Duration.zero);
      return vm;
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('isOrganizer is true for the trip organizer', () async {
      final vm = await open(await seedTrip(organizerId: me));
      expect(vm.isOrganizer, isTrue);
    });

    test('isOrganizer is false for a member', () async {
      final vm = await open(await seedTrip(organizerId: 'u2'));
      expect(vm.isOrganizer, isFalse);
    });

    test('isOrganizer is false when the trip does not exist', () async {
      final vm = await open('missing');
      expect(vm.isOrganizer, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.polls, isEmpty);
    });

    group('createPoll rejects', () {
      final cases = <String, (String, String, String)>{
        'empty question': ('  ', 'A\nB', 'Enter a question.'),
        'fewer than 2 options': (
          'Q',
          'Only one\n\n',
          'Add at least 2 options, one per line.',
        ),
        'duplicate options': (
          'Q',
          ' Pizza \n pizza',
          'Each option must be different.',
        ),
      };
      cases.forEach((name, c) {
        test(name, () async {
          final tripId = await seedTrip(organizerId: me);
          final vm = await open(tripId);
          final error = await vm.createPoll(question: c.$1, options: c.$2);
          expect(error, c.$3);
          expect(await polls.watchPolls(tripId).first, isEmpty);
        });
      });

      test('when not organizer', () async {
        final tripId = await seedTrip(organizerId: 'u2');
        final vm = await open(tripId);
        final error = await vm.createPoll(question: 'Q', options: 'A\nB');
        expect(error, 'Only the organizer can create polls.');
        expect(await polls.watchPolls(tripId).first, isEmpty);
      });
    });

    test('createPoll saves a valid poll', () async {
      final vm = await open(await seedTrip(organizerId: me));
      final error = await vm.createPoll(
        question: ' Day 2 afternoon? ',
        options: 'Vatican Museums\n\nCooking class\n',
      );
      await settle();

      expect(error, isNull);
      final poll = vm.polls.single;
      expect(poll.question, 'Day 2 afternoon?');
      expect(poll.options, ['Vatican Museums', 'Cooking class']);
      expect(poll.createdBy, me);
    });

    test("vote records the current user's choice and can change it", () async {
      final vm = await open(await seedTrip(organizerId: me));
      await vm.createPoll(question: 'Q', options: 'A\nB');
      await settle();

      expect(await vm.vote(vm.polls.single, 'A'), isNull);
      await settle();
      expect(vm.polls.single.voteOf(me), 'A');

      expect(await vm.vote(vm.polls.single, 'B'), isNull);
      await settle();
      expect(vm.polls.single.countFor('A'), 0);
      expect(vm.polls.single.countFor('B'), 1);
    });

    test('vote rejects an option not in the poll', () async {
      final vm = await open(await seedTrip(organizerId: me));
      await vm.createPoll(question: 'Q', options: 'A\nB');
      await settle();

      final error = await vm.vote(vm.polls.single, 'C');
      await settle();
      expect(error, 'That option is no longer in this poll.');
      expect(vm.polls.single.votes, isEmpty);
    });
  });
}
