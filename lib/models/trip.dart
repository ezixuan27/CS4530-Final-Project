/// A group trip (Stories 2, 3, 6).
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
