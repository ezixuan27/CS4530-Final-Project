import 'dart:async';
import 'dart:math';

import '../models/trip.dart';
import 'trip_repository.dart';

/// In-memory stand-in for tests: data lives in memory and is lost on restart.
class InMemoryTripRepository implements TripRepository {
  final Map<String, Trip> _trips = {};
  final Random _random = Random();
  int _nextId = 1;

  /// Fires after every create or join so the watch streams can re-emit.
  final StreamController<void> _changes = StreamController<void>.broadcast();

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
    _changes.add(null);
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
    _changes.add(null);
    return updated;
  }

  @override
  Future<Trip?> tripById(String id) async => _trips[id];

  @override
  Stream<List<Trip>> watchTripsForUser(String userId) => _watch(
    () => _trips.values.where((t) => t.memberIds.contains(userId)).toList(),
  );

  @override
  Stream<Trip?> watchTrip(String id) => _watch(() => _trips[id]);

  /// Emits [read]'s value on listen, then again after every change.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }
}
