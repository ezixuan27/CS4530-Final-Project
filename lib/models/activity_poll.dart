/// A question the organizer posts for members to vote on (Story 7).
class ActivityPoll {
  final String id;
  final String tripId;
  final String question;
  final List<String> options;

  /// userId -> chosen option. One vote per member; voting again replaces it.
  final Map<String, String> votes;

  /// User id of the organizer who created the poll.
  final String createdBy;

  final DateTime createdAt;

  const ActivityPoll({
    required this.id,
    required this.tripId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    this.votes = const {},
  });

  /// Number of votes for [option].
  int countFor(String option) => votes.values.where((v) => v == option).length;

  /// The option [userId] voted for, or null if they haven't voted.
  String? voteOf(String userId) => votes[userId];
}
