import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/features/trips/view_models/join_trip_view_model.dart';
import 'package:final_project/models/trip.dart';

class _BrokenTrips extends InMemoryTripRepository {
  @override
  Future<Trip?> joinTrip(String inviteCode, String userId) =>
      throw Exception('offline');
}

void main() {
  late InMemoryTripRepository trips;
  late JoinTripViewModel vm;
  late Trip friendsTrip;
  final me = AuthService.testUser.id;

  setUp(() async {
    trips = InMemoryTripRepository();
    vm = JoinTripViewModel(repository: trips, auth: InMemoryAuthService());
    friendsTrip = await trips.createTrip(
      name: 'Lisbon Weekend',
      destination: 'Lisbon',
      startDate: DateTime(2027, 5, 1),
      endDate: DateTime(2027, 5, 3),
      organizerId: 'friend',
    );
  });

  test('validateCode', () {
    expect(JoinTripViewModel.validateCode('  '), 'Enter an invite code.');
    expect(
      JoinTripViewModel.validateCode('ABC'),
      'Invite codes are 6 characters.',
    );
    expect(JoinTripViewModel.validateCode(' rme27a '), isNull);
  });

  test('right code joins me as a member', () async {
    final trip = await vm.join(friendsTrip.inviteCode);
    expect(trip?.id, friendsTrip.id);
    expect(vm.error, isNull);
    expect(trip!.roleOf(me), TripRole.member);
    expect(await trips.tripsForUser(me), hasLength(1));
  });

  test('lowercase code with spaces still works', () async {
    final trip = await vm.join(' ${friendsTrip.inviteCode.toLowerCase()} ');
    expect(trip?.id, friendsTrip.id);
  });

  test('unknown code shows an error', () async {
    final trip = await vm.join('ZZZZZZ');
    expect(trip, isNull);
    expect(vm.error, 'No trip found with that code.');
    expect(await trips.tripsForUser(me), isEmpty);
  });

  test('joining twice is harmless', () async {
    await vm.join(friendsTrip.inviteCode);
    final again = await vm.join(friendsTrip.inviteCode);
    expect(again?.id, friendsTrip.id);
    expect(vm.error, isNull);
    expect(again!.memberIds.where((id) => id == me), hasLength(1));
  });

  test('organizer joining their own trip stays organizer', () async {
    final mine = await trips.createTrip(
      name: 'Mine',
      destination: 'Rome',
      startDate: DateTime(2027, 4, 10),
      endDate: DateTime(2027, 4, 18),
      organizerId: me,
    );
    final trip = await vm.join(mine.inviteCode);
    expect(trip!.roleOf(me), TripRole.organizer);
  });

  test('short code is caught before calling the repo', () async {
    final trip = await vm.join('ABC');
    expect(trip, isNull);
    expect(vm.error, 'Invite codes are 6 characters.');
  });

  test('repository failure shows a message', () async {
    final broken = JoinTripViewModel(
      repository: _BrokenTrips(),
      auth: InMemoryAuthService(),
    );
    final trip = await broken.join('ABCDEF');
    expect(trip, isNull);
    expect(broken.error, 'Could not join the trip. Try again.');
    expect(broken.isJoining, isFalse);
  });

  test('clearError removes the message', () async {
    await vm.join('');
    expect(vm.error, isNotNull);
    vm.clearError();
    expect(vm.error, isNull);
  });
}
