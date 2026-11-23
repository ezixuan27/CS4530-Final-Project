import 'dart:async';

import '../../../models/activity_poll.dart';
import 'poll_repository.dart';

/// Fake for tests: data lives in memory and is lost on restart.
class InMemoryPollRepository implements PollRepository {
  final List<ActivityPoll> _polls = [];
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 1;

  List<ActivityPoll> _forTrip(String tripId) {
    final list = _polls.where((p) => p.tripId == tripId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<ActivityPoll>> watchPolls(String tripId) {
    // A controller (not async*) so cancelling the stream stops listening
    // to _changes right away.
    StreamSubscription<void>? changesSub;
    late final StreamController<List<ActivityPoll>> controller;
    controller = StreamController(
      onListen: () {
        controller.add(_forTrip(tripId));
        changesSub = _changes.stream.listen(
          (_) => controller.add(_forTrip(tripId)),
        );
      },
      onCancel: () => changesSub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
    required String createdBy,
  }) async {
    _polls.add(
      ActivityPoll(
        id: 'poll${_nextId++}',
        tripId: tripId,
        question: question,
        options: List.unmodifiable(options),
        createdBy: createdBy,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> vote({
    required String tripId,
    required String pollId,
    required String userId,
    required String option,
  }) async {
    final index = _polls.indexWhere(
      (p) => p.id == pollId && p.tripId == tripId,
    );
    if (index == -1) throw StateError('Poll $pollId not found');
    final poll = _polls[index];
    _polls[index] = ActivityPoll(
      id: poll.id,
      tripId: poll.tripId,
      question: poll.question,
      options: poll.options,
      createdBy: poll.createdBy,
      createdAt: poll.createdAt,
      votes: Map.unmodifiable({...poll.votes, userId: option}),
    );
    _changes.add(null);
  }
}
