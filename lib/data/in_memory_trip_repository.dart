import 'dart:math';

import '../models/trip.dart';
import 'trip_repository.dart';

/// Temporary fake: data lives in memory and is lost on restart.
class InMemoryTripRepository implements TripRepository {
  final Map<String, Trip> _trips = {};
  final Random _random = Random();
  int _nextId = 1;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newInviteCode() {
    String code;
    do {
      code = List.generate(
        6,
        (_) => _codeChars[_random.nextInt(_codeChars.length)],
      ).join();
    } while (_trips.values.any((t) => t.inviteCode == code));
    return code;
  }

  @override
  Future<List<Trip>> tripsForUser(String userId) async =>
      _trips.values.where((t) => t.memberIds.contains(userId)).toList();

  @override
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  }) async {
    final trip = Trip(
      id: 'trip${_nextId++}',
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      inviteCode: _newInviteCode(),
      organizerId: organizerId,
      memberIds: [organizerId],
    );
    _trips[trip.id] = trip;
    return trip;
  }

  @override
  Future<Trip?> joinTrip(String inviteCode, String userId) async {
    final code = inviteCode.trim().toUpperCase();
    final matches = _trips.values.where((t) => t.inviteCode == code);
    if (matches.isEmpty) return null;
    final trip = matches.first;
    if (trip.memberIds.contains(userId)) return trip;
    final updated = trip.copyWith(memberIds: [...trip.memberIds, userId]);
    _trips[trip.id] = updated;
    return updated;
  }

  @override
  Future<Trip?> tripById(String id) async => _trips[id];
}
