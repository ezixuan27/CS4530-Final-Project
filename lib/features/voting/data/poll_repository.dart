import '../../../models/activity_poll.dart';

/// Data access for a trip's activity polls (Story 7).
abstract class PollRepository {
  /// The trip's polls, newest first. Emits again whenever a poll is created
  /// or someone votes, including other trip members (10-second sync NFR).
  Stream<List<ActivityPoll>> watchPolls(String tripId);

  Future<void> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
    required String createdBy,
  });

  /// Records [userId]'s vote, replacing any earlier vote in this poll.
  Future<void> vote({
    required String tripId,
    required String pollId,
    required String userId,
    required String option,
  });
}
