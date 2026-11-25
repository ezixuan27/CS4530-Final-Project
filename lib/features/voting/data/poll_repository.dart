import '../../../models/activity_poll.dart';

/// One option row in an edited poll. [from] is the option's text before the
/// edit, or null for a newly added option. [to] is its text after the edit.
class PollOptionEdit {
  final String? from;
  final String to;

  const PollOptionEdit({this.from, required this.to});
}

/// Votes after an edit: a vote on [PollOptionEdit.from] moves to its
/// [PollOptionEdit.to]; a vote on an option with no edit row is dropped.
Map<String, String> remapVotes(
  Map<String, String> votes,
  List<PollOptionEdit> options,
) {
  final renamed = {
    for (final o in options)
      if (o.from != null) o.from!: o.to,
  };
  return {
    for (final entry in votes.entries)
      if (renamed.containsKey(entry.value)) entry.key: renamed[entry.value]!,
  };
}

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

  /// Replaces the poll's question and options. Votes follow
  /// [remapVotes]. [options] must already be trimmed and validated.
  /// Throws if the poll doesn't exist.
  Future<void> editPoll({
    required String tripId,
    required String pollId,
    required String question,
    required List<PollOptionEdit> options,
  });
}
