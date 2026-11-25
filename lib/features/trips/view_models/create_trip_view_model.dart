import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/trip.dart';

/// State for the Create Trip screen (Story 2).
class CreateTripViewModel extends ChangeNotifier {
  CreateTripViewModel({required this._repository, required this._auth});

  final TripRepository _repository;
  final AuthService _auth;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  String? _error;
  Trip? _createdTrip;
  bool _disposed = false;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isSaving => _isSaving;

  /// Message to show under the form, or null.
  String? get error => _error;

  /// Set once the trip is saved, then the screen shows the invite code.
  Trip? get createdTrip => _createdTrip;

  void setStartDate(DateTime date) {
    _startDate = _dayOnly(date);
    // moving the start past the end makes the end wrong, so clear it
    if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
    _error = null;
    _notify();
  }

  void setEndDate(DateTime date) {
    _endDate = _dayOnly(date);
    _error = null;
    _notify();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  /// Saves the trip with the current user as organizer.
  /// Returns true if it worked.
  Future<bool> create({
    required String name,
    required String destination,
  }) async {
    final problem =
        validateName(name) ??
        validateDestination(destination) ??
        validateDates(_startDate, _endDate);
    if (problem != null) {
      _error = problem;
      _notify();
      return false;
    }

    _error = null;
    _isSaving = true;
    _notify();
    try {
      _createdTrip = await _repository.createTrip(
        name: name.trim(),
        destination: destination.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        organizerId: _auth.currentUser.id,
      );
      return true;
    } catch (_) {
      _error = 'Could not create the trip. Try again.';
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  // static so the form fields can use them too
  static String? validateName(String name) =>
      name.trim().isEmpty ? 'Enter a trip name.' : null;

  static String? validateDestination(String destination) =>
      destination.trim().isEmpty ? 'Enter a destination.' : null;

  static String? validateDates(DateTime? start, DateTime? end) {
    if (start == null) return 'Pick a start date.';
    if (end == null) return 'Pick an end date.';
    if (end.isBefore(start)) return "End date can't be before the start date.";
    return null;
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. "Apr 10, 2027"
  static String formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // the screen can close while saving
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
