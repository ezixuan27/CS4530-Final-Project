/// Options the organizer posts for members to vote on (Story 7).
class ActivityPoll {
  final String id;
  final String tripId;
  final List<String> options;

  /// userId -> chosen option.
  final Map<String, String> votes;

  const ActivityPoll({
    required this.id,
    required this.tripId,
    required this.options,
    this.votes = const {},
  });
}
