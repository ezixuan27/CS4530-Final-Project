import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/features/voting/data/firestore_poll_repository.dart';
import 'package:final_project/features/voting/data/in_memory_poll_repository.dart';
import 'package:final_project/features/voting/data/poll_repository.dart';
import 'package:final_project/models/activity_poll.dart';

/// Both implementations must behave the same, so the same tests run on each.
void main() {
  final implementations = <String, PollRepository Function()>{
    'InMemoryPollRepository': InMemoryPollRepository.new,
    'FirestorePollRepository': () =>
        FirestorePollRepository(FakeFirebaseFirestore()),
  };

  implementations.forEach((name, create) {
    group(name, () {
      late PollRepository repo;
      setUp(() => repo = create());

      Future<void> create_(String tripId, String question) => repo.createPoll(
        tripId: tripId,
        question: question,
        options: const ['Vatican Museums', 'Cooking class'],
        createdBy: 'u1',
      );

      Future<ActivityPoll> onlyPoll(String tripId) async =>
          (await repo.watchPolls(tripId).first).single;

      Future<void> vote(ActivityPoll poll, String userId, String option) =>
          repo.vote(
            tripId: poll.tripId,
            pollId: poll.id,
            userId: userId,
            option: option,
          );

      test('starts with an empty list', () async {
        expect(await repo.watchPolls('trip1').first, isEmpty);
      });

      test('created poll is stored with all fields and no votes', () async {
        await create_('trip1', 'Day 2 afternoon?');

        final poll = await onlyPoll('trip1');
        expect(poll.id, isNotEmpty);
        expect(poll.tripId, 'trip1');
        expect(poll.question, 'Day 2 afternoon?');
        expect(poll.options, ['Vatican Museums', 'Cooking class']);
        expect(poll.createdBy, 'u1');
        expect(poll.votes, isEmpty);
      });

      test('only returns polls for the requested trip', () async {
        await create_('trip1', 'Q1');
        await create_('trip2', 'Q2');

        final list = await repo.watchPolls('trip1').first;
        expect(list.map((p) => p.question), ['Q1']);
      });

      test('newest poll comes first', () async {
        await create_('trip1', 'First');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await create_('trip1', 'Second');

        final list = await repo.watchPolls('trip1').first;
        expect(list.map((p) => p.question), ['Second', 'First']);
      });

      test('vote is recorded for the user', () async {
        await create_('trip1', 'Q');
        await vote(await onlyPoll('trip1'), 'u1', 'Cooking class');

        expect((await onlyPoll('trip1')).voteOf('u1'), 'Cooking class');
      });

      test('changing a vote replaces it', () async {
        await create_('trip1', 'Q');
        final poll = await onlyPoll('trip1');
        await vote(poll, 'u1', 'Vatican Museums');
        await vote(poll, 'u1', 'Cooking class');

        final updated = await onlyPoll('trip1');
        expect(updated.countFor('Vatican Museums'), 0);
        expect(updated.countFor('Cooking class'), 1);
      });

      test('votes from different users are kept', () async {
        await create_('trip1', 'Q');
        final poll = await onlyPoll('trip1');
        await vote(poll, 'u1', 'Vatican Museums');
        await vote(poll, 'u2', 'Cooking class');

        expect((await onlyPoll('trip1')).votes, {
          'u1': 'Vatican Museums',
          'u2': 'Cooking class',
        });
      });

      test('watchPolls emits again after a vote', () async {
        await create_('trip1', 'Q');
        final poll = await onlyPoll('trip1');

        final voted = repo
            .watchPolls('trip1')
            .firstWhere((list) => list.single.voteOf('u2') == 'Cooking class');
        await vote(poll, 'u2', 'Cooking class');

        expect((await voted.timeout(const Duration(seconds: 2))).single.votes, {
          'u2': 'Cooking class',
        });
      });
    });
  });
}
