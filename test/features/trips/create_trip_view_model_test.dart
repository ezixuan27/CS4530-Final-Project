import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';
import 'package:final_project/data/in_memory_trip_repository.dart';
import 'package:final_project/features/trips/view_models/create_trip_view_model.dart';
import 'package:final_project/models/trip.dart';

class _BrokenTrips extends InMemoryTripRepository {
  @override
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String organizerId,
  }) => throw Exception('offline');
}

void main() {
  late InMemoryTripRepository trips;
  late CreateTripViewModel vm;

  setUp(() {
    trips = InMemoryTripRepository();
    vm = CreateTripViewModel(repository: trips, auth: InMemoryAuthService());
  });

  void pickDates() {
    vm.setStartDate(DateTime(2027, 4, 10));
    vm.setEndDate(DateTime(2027, 4, 18));
  }

  group('validation', () {
    test('name and destination are required', () {
      expect(CreateTripViewModel.validateName('  '), 'Enter a trip name.');
      expect(CreateTripViewModel.validateName('Italy'), isNull);
      expect(
        CreateTripViewModel.validateDestination(''),
        'Enter a destination.',
      );
      expect(CreateTripViewModel.validateDestination('Rome'), isNull);
    });

    test('dates', () {
      final apr10 = DateTime(2027, 4, 10);
      final apr18 = DateTime(2027, 4, 18);
      expect(
        CreateTripViewModel.validateDates(null, apr18),
        'Pick a start date.',
      );
      expect(
        CreateTripViewModel.validateDates(apr10, null),
        'Pick an end date.',
      );
      expect(
        CreateTripViewModel.validateDates(apr18, apr10),
        "End date can't be before the start date.",
      );
      expect(CreateTripViewModel.validateDates(apr10, apr18), isNull);
      // one day trip is fine
      expect(CreateTripViewModel.validateDates(apr10, apr10), isNull);
    });
  });

  test('creates the trip with me as organizer', () async {
    pickDates();
    final ok = await vm.create(name: ' Italy Getaway ', destination: 'Rome ');

    expect(ok, isTrue);
    expect(vm.error, isNull);
    final trip = vm.createdTrip!;
    expect(trip.name, 'Italy Getaway');
    expect(trip.destination, 'Rome');
    expect(trip.inviteCode, hasLength(6));
    expect(trip.roleOf(AuthService.testUser.id), TripRole.organizer);
    expect(await trips.tripsForUser(AuthService.testUser.id), hasLength(1));
  });

  test('missing dates show an error and save nothing', () async {
    final ok = await vm.create(name: 'Italy', destination: 'Rome');
    expect(ok, isFalse);
    expect(vm.error, 'Pick a start date.');
    expect(vm.createdTrip, isNull);
    expect(await trips.tripsForUser(AuthService.testUser.id), isEmpty);
  });

  test('moving the start after the end clears the end', () {
    pickDates();
    vm.setStartDate(DateTime(2027, 4, 20));
    expect(vm.endDate, isNull);
  });

  test('moving the start but still before the end keeps the end', () {
    pickDates();
    vm.setStartDate(DateTime(2027, 4, 12));
    expect(vm.endDate, DateTime(2027, 4, 18));
  });

  test('dates drop the time part', () {
    vm.setStartDate(DateTime(2027, 4, 10, 15, 30));
    expect(vm.startDate, DateTime(2027, 4, 10));
  });

  test('repository failure shows a message', () async {
    final broken = CreateTripViewModel(
      repository: _BrokenTrips(),
      auth: InMemoryAuthService(),
    );
    broken.setStartDate(DateTime(2027, 4, 10));
    broken.setEndDate(DateTime(2027, 4, 18));
    final ok = await broken.create(name: 'Italy', destination: 'Rome');
    expect(ok, isFalse);
    expect(broken.error, 'Could not create the trip. Try again.');
    expect(broken.isSaving, isFalse);
  });

  test('picking a date clears the error', () async {
    await vm.create(name: 'Italy', destination: 'Rome');
    expect(vm.error, isNotNull);
    vm.setStartDate(DateTime(2027, 4, 10));
    expect(vm.error, isNull);
  });

  test('formatDate', () {
    expect(
      CreateTripViewModel.formatDate(DateTime(2027, 4, 10)),
      'Apr 10, 2027',
    );
    expect(
      CreateTripViewModel.formatDate(DateTime(2027, 12, 1)),
      'Dec 1, 2027',
    );
  });
}
