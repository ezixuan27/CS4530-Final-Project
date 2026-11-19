import '../models/trip.dart';

/// Data access for trips. Screens depend on this interface only, so the
/// in-memory version can later be swapped for a real database.
///
/// Add methods here as you build your stories (itinerary, polls, expenses...).
abstract class TripRepository {
  Future<List<Trip>> tripsForUser(String userId);

  Future<Trip> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  });

  /// Returns the joined trip, or null if no trip has [inviteCode].
  Future<Trip?> joinTrip(String inviteCode, String userId);

  Future<Trip?> tripById(String id);
}
