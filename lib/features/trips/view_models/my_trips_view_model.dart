import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/trip.dart';

/// State and logic for My Trips (Story 6). The view only renders this.
class MyTripsViewModel extends ChangeNotifier {
  final TripRepository _repository;
  final AuthService _auth;

  MyTripsViewModel({required this._repository, required this._auth});

  bool _isLoading = true;
  List<Trip> _trips = const [];
  bool _disposed = false;

  bool get isLoading => _isLoading;
  List<Trip> get trips => _trips;

  /// Loads the trips the signed-in user created or joined.
  Future<void> load() async {
    _isLoading = true;
    _notify();
    final trips = await _repository.tripsForUser(_auth.currentUser.id);
    _trips = List.unmodifiable(trips);
    _isLoading = false;
    _notify();
  }

  Future<void> signOut() => _auth.signOut();

  // The screen can be closed while a load is still running.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
