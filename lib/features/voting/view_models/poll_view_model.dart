import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/activity_poll.dart';
import '../../../models/trip.dart';
import '../data/poll_repository.dart';

/// State and logic for a trip's Vote for an Activity screen (Story 7).
class PollViewModel extends ChangeNotifier {
  final PollRepository _polls;
  final AuthService _auth;
  final String tripId;

  late final StreamSubscription<List<ActivityPoll>> _pollsSub;
  late final StreamSubscription<Trip?> _tripSub;
  bool _isLoading = true;
  List<ActivityPoll> _pollList = const [];
  Trip? _trip;

  /// Starts listening to the trip's polls and to the trip (for the
  /// organizer role) right away, once.
  PollViewModel({
    required this._polls,
    required TripRepository trips,
    required this._auth,
    required this.tripId,
  }) {
    _pollsSub = _polls.watchPolls(tripId).listen((list) {
      _pollList = list;
      _isLoading = false;
      notifyListeners();
    });
    _tripSub = trips.watchTrip(tripId).listen((trip) {
      _trip = trip;
      notifyListeners();
    });
  }

  bool get isLoading => _isLoading;

  /// Newest first.
  List<ActivityPoll> get polls => _pollList;

  String get currentUserId => _auth.currentUser.id;

  /// False while the trip is still loading or doesn't exist.
  bool get isOrganizer => _trip?.roleOf(currentUserId) == TripRole.organizer;

  /// Creates a poll from a question and options typed one per line.
  /// Returns an error message to show, or null on success.
  Future<String?> createPoll({
    required String question,
    required String options,
  }) async {
    if (!isOrganizer) return 'Only the organizer can create polls.';
    final trimmed = question.trim();
    if (trimmed.isEmpty) return 'Enter a question.';
    final parsed = parseOptions(options);
    if (parsed.length < 2) return 'Add at least 2 options, one per line.';
    if (parsed.map((o) => o.toLowerCase()).toSet().length != parsed.length) {
      return 'Each option must be different.';
    }
    return _save(
      () => _polls.createPoll(
        tripId: tripId,
        question: trimmed,
        options: parsed,
        createdBy: currentUserId,
      ),
    );
  }

  /// Votes for [option] in [poll], replacing the user's earlier vote.
  /// Returns an error message to show, or null on success.
  Future<String?> vote(ActivityPoll poll, String option) async {
    if (!poll.options.contains(option)) {
      return 'That option is no longer in this poll.';
    }
    return _save(
      () => _polls.vote(
        tripId: tripId,
        pollId: poll.id,
        userId: currentUserId,
        option: option,
      ),
    );
  }

  Future<String?> _save(Future<void> Function() write) async {
    try {
      await write();
      return null;
    } catch (_) {
      return 'Could not save. Try again.';
    }
  }

  /// One option per line: trims each line and drops empty ones.
  static List<String> parseOptions(String input) => [
    for (final line in input.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  @override
  void dispose() {
    _pollsSub.cancel();
    _tripSub.cancel();
    super.dispose();
  }
}
