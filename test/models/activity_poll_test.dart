import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/models/activity_poll.dart';

void main() {
  final poll = ActivityPoll(
    id: 'poll1',
    tripId: 'trip1',
    question: 'Day 2 afternoon?',
    options: const ['A', 'B', 'C'],
    createdBy: 'u1',
    createdAt: DateTime(2026, 11, 23),
    votes: const {'u1': 'A', 'u2': 'A', 'u3': 'B'},
  );

  test('countFor counts votes per option', () {
    expect(poll.countFor('A'), 2);
    expect(poll.countFor('B'), 1);
    expect(poll.countFor('C'), 0);
  });

  test("voteOf returns the user's option or null", () {
    expect(poll.voteOf('u1'), 'A');
    expect(poll.voteOf('u9'), isNull);
  });
}
