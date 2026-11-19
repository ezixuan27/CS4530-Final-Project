import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/in_memory_trip_repository.dart';

void main() {
  late InMemoryTripRepository repo;

  setUp(() => repo = InMemoryTripRepository());

  Future<String> createItaly() async {
    final trip = await repo.createTrip(
      name: 'Italy Getaway',
      destination: 'Rome',
      startDate: DateTime(2027, 4, 10),
      endDate: DateTime(2027, 4, 18),
      organizerId: 'u1',
    );
    return trip.inviteCode;
  }

  test('createTrip generates a 6-character invite code', () async {
    final code = await createItaly();
    expect(code, hasLength(6));
  });

  test('joinTrip with a valid code adds the user as a member', () async {
    final code = await createItaly();
    final joined = await repo.joinTrip(code, 'u2');
    expect(joined, isNotNull);
    expect(joined!.memberIds, containsAll(['u1', 'u2']));
    expect(await repo.tripsForUser('u2'), hasLength(1));
  });

  test('joinTrip with an unknown code returns null', () async {
    await createItaly();
    expect(await repo.joinTrip('BAD000', 'u2'), isNull);
  });
}
