import '../models/trip.dart';

/// Data access for trips: create, join, and look up (Stories 2, 3, 6).
/// Screens depend on this interface only, so the in-memory version can later
/// be swapped for a real database.
///
/// Keep this to trip-level operations. Itinerary, polls, and expenses each get
/// their own repository in their owner's feature folder, so we don't all edit
/// this file at once.
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

  /// Live version of [tripsForUser]: emits the current list, then again
  /// whenever one of the user's trips changes (10-second sync NFR).
  Stream<List<Trip>> watchTripsForUser(String userId);

  /// Live version of [tripById]: emits null if the trip doesn't exist.
  Stream<Trip?> watchTrip(String id);
}
