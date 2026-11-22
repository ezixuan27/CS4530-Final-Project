/// A user's role in one trip. Use [Trip.roleOf] instead of comparing ids.
enum TripRole { organizer, member }

/// A group trip (Stories 2, 3, 6).
///
/// Roles are stored as [organizerId] (the one organizer) and [memberIds]
/// (everyone in the trip, organizer included).
class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  /// Code friends type in to join, e.g. "RME27A".
  final String inviteCode;
  final String organizerId;
  final List<String> memberIds;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
    required this.organizerId,
    required this.memberIds,
  });

  /// [userId]'s role in this trip, or null if they aren't in it.
  /// e.g. `trip.roleOf(auth.currentUser.id) == TripRole.organizer`
  TripRole? roleOf(String userId) {
    if (userId == organizerId) return TripRole.organizer;
    if (memberIds.contains(userId)) return TripRole.member;
    return null;
  }

  Trip copyWith({List<String>? memberIds}) => Trip(
    id: id,
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    inviteCode: inviteCode,
    organizerId: organizerId,
    memberIds: memberIds ?? this.memberIds,
  );
}
