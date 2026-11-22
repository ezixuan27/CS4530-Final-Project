import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trip.dart';
import 'trip_repository.dart';

/// [TripRepository] backed by Cloud Firestore.
///
/// Layout:
/// ```
/// trips/{tripId}       name, destination, startDate, endDate (Timestamp),
///                      inviteCode, organizerId, memberIds, createdAt
/// inviteCodes/{code}   tripId
/// ```
/// Roles: `organizerId` is the organizer, `memberIds` is everyone in the trip
/// (organizer included). Read them with [Trip.roleOf].
///
/// `inviteCodes` lets someone who isn't a member yet turn a code into a trip
/// id, so security rules can keep trips readable by members only.
class FirestoreTripRepository implements TripRepository {
  FirestoreTripRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');
  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _db.collection('inviteCodes');

  // No 0/O or 1/I so codes are easy to read aloud.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 6;
  static const _maxCodeAttempts = 5;

  String _newInviteCode() => List.generate(
    _codeLength,
    (_) => _codeChars[_random.nextInt(_codeChars.length)],
  ).join();

  @override
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  }) async {
    final tripRef = _trips.doc();

    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final code = _newInviteCode();
      final codeRef = _inviteCodes.doc(code);

      // Claim the code and create the trip together, so two trips can never
      // end up with the same code.
      final created = await _db.runTransaction((tx) async {
        final existing = await tx.get(codeRef);
        if (existing.exists) return false;
        tx.set(codeRef, {'tripId': tripRef.id});
        tx.set(tripRef, {
          'name': name,
          'destination': destination,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'inviteCode': code,
          'organizerId': organizerId,
          'memberIds': [organizerId],
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (created) {
        return Trip(
          id: tripRef.id,
          name: name,
          destination: destination,
          startDate: startDate,
          endDate: endDate,
          inviteCode: code,
          organizerId: organizerId,
          memberIds: [organizerId],
        );
      }
    }
    throw StateError('Could not generate a unique invite code. Try again.');
  }

  @override
  Future<Trip?> joinTrip(String inviteCode, String userId) async {
    final code = inviteCode.trim().toUpperCase();
    // Anything else can't be a code, and characters like "/" would break the
    // document path.
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) return null;

    final codeSnap = await _inviteCodes.doc(code).get();
    final tripId = codeSnap.data()?['tripId'] as String?;
    if (tripId == null) return null;

    final trip = await tripById(tripId);
    if (trip == null) return null;
    // Joining twice is harmless, and the organizer keeps their role.
    if (trip.memberIds.contains(userId)) return trip;

    // arrayUnion adds the id only if it's missing, even if two joins race.
    await _trips.doc(tripId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    return trip.copyWith(memberIds: [...trip.memberIds, userId]);
  }

  @override
  Future<List<Trip>> tripsForUser(String userId) async {
    final snap = await _tripsForUserQuery(userId).get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<Trip?> tripById(String id) async {
    final snap = await _trips.doc(id).get();
    return snap.exists ? _fromDoc(snap) : null;
  }

  @override
  Stream<List<Trip>> watchTripsForUser(String userId) =>
      _tripsForUserQuery(userId)
          .snapshots()
          .map((snap) => snap.docs.map(_fromDoc).toList());

  @override
  Stream<Trip?> watchTrip(String id) => _trips
      .doc(id)
      .snapshots()
      .map((snap) => snap.exists ? _fromDoc(snap) : null);

  Query<Map<String, dynamic>> _tripsForUserQuery(String userId) =>
      _trips.where('memberIds', arrayContains: userId);

  Trip _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Trip(
      id: doc.id,
      name: data['name'] as String,
      destination: data['destination'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      inviteCode: data['inviteCode'] as String,
      organizerId: data['organizerId'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
    );
  }
}
