import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/trip.dart';

/// State for the Join Trip screen (Story 3).
class JoinTripViewModel extends ChangeNotifier {
  JoinTripViewModel({required this._repository, required this._auth});

  final TripRepository _repository;
  final AuthService _auth;

  bool _isJoining = false;
  String? _error;
  bool _disposed = false;

  bool get isJoining => _isJoining;

  /// Message to show under the field, or null.
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  /// Joins the trip with [code] as the current user.
  /// Returns the trip, or null if it didn't work (then [error] says why).
  Future<Trip?> join(String code) async {
    final problem = validateCode(code);
    if (problem != null) {
      _error = problem;
      _notify();
      return null;
    }

    _error = null;
    _isJoining = true;
    _notify();
    try {
      // already a member is fine, the repo just hands the trip back
      final trip = await _repository.joinTrip(
        normalize(code),
        _auth.currentUser.id,
      );
      if (trip == null) _error = 'No trip found with that code.';
      return trip;
    } catch (_) {
      _error = 'Could not join the trip. Try again.';
      return null;
    } finally {
      _isJoining = false;
      _notify();
    }
  }

  /// " rme27a " -> "RME27A"
  static String normalize(String code) => code.trim().toUpperCase();

  static String? validateCode(String code) {
    final c = normalize(code);
    if (c.isEmpty) return 'Enter an invite code.';
    if (c.length != 6) return 'Invite codes are 6 characters.';
    return null;
  }

  // the screen can close while joining
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
