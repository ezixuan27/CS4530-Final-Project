/// One stop in a trip's plan, e.g. "Colosseum, 9 AM, North gate" (Stories 5, 6).
class ItineraryItem {
  final String id;
  final String tripId;
  final String title;
  final DateTime time;
  final String meetingPoint;

  const ItineraryItem({
    required this.id,
    required this.tripId,
    required this.title,
    required this.time,
    required this.meetingPoint,
  });
}
