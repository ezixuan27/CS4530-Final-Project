import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/features/trips/view_models/my_trips_view_model.dart';

void main() {
  late InMemoryTripRepository repo;
  late MyTripsViewModel vm;

  Future<void> createTrip(String name, String organizerId) => repo.createTrip(
    name: name,
    destination: 'Somewhere',
    startDate: DateTime(2027, 4, 10),
    endDate: DateTime(2027, 4, 18),
    organizerId: organizerId,
  );

  setUp(() {
    repo = InMemoryTripRepository();
    vm = MyTripsViewModel(repository: repo, auth: InMemoryAuthService());
  });

  test('starts loading with no trips', () {
    expect(vm.isLoading, isTrue);
    expect(vm.trips, isEmpty);
  });

  test('load() returns only the current user\'s trips', () async {
    await createTrip('Mine', AuthService.testUser.id);
    await createTrip('Theirs', 'someone-else');

    await vm.load();

    expect(vm.isLoading, isFalse);
    expect(vm.trips.map((t) => t.name), ['Mine']);
  });

  test('load() notifies listeners when done', () async {
    var notified = 0;
    vm.addListener(() => notified++);

    await vm.load();

    expect(notified, greaterThan(0));
  });

  test('load() picks up trips created since the last load', () async {
    await vm.load();
    await createTrip('New', AuthService.testUser.id);

    await vm.load();

    expect(vm.trips.map((t) => t.name), ['New']);
  });

  test('disposing while load() is in flight does not throw', () async {
    final pending = vm.load();
    vm.dispose();
    await expectLater(pending, completes);
  });
}
