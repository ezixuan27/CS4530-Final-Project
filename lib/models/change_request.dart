enum ChangeStatus { pending, approved, declined }

/// A member's proposed change to an itinerary item (Stories 4, 5).
class ChangeRequest {
  final String id;
  final String itemId;
  final String proposedBy;
  final String proposedMeetingPoint;
  final ChangeStatus status;

  const ChangeRequest({
    required this.id,
    required this.itemId,
    required this.proposedBy,
    required this.proposedMeetingPoint,
    this.status = ChangeStatus.pending,
  });
}
