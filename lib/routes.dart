import 'package:flutter/material.dart';

import 'features/auth/register_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/itinerary/itinerary_screen.dart';
import 'features/itinerary/review_suggestions_screen.dart';
import 'features/itinerary/suggest_change_screen.dart';
import 'features/trips/create_trip_screen.dart';
import 'features/trips/join_trip_screen.dart';
import 'features/trips/my_trips_screen.dart';
import 'features/voting/vote_activity_screen.dart';

/// Route names. Trip-scoped screens receive the trip id (String) as the
/// route argument: `Navigator.pushNamed(context, Routes.itinerary, arguments: tripId)`.
class Routes {
  static const signIn = '/';
  static const register = '/register';
  static const myTrips = '/trips';
  static const createTrip = '/trips/create';
  static const joinTrip = '/trips/join';
  static const itinerary = '/trip/itinerary';
  static const suggestChange = '/trip/suggest-change';
  static const reviewSuggestions = '/trip/review-suggestions';
  static const voteActivity = '/trip/vote';
  static const expenses = '/trip/expenses';

  static final Map<String, WidgetBuilder> table = {
    signIn: (_) => const SignInScreen(),
    register: (_) => const RegisterScreen(),
    myTrips: (_) => const MyTripsScreen(),
    createTrip: (_) => const CreateTripScreen(),
    joinTrip: (_) => const JoinTripScreen(),
    itinerary: (_) => const ItineraryScreen(),
    suggestChange: (_) => const SuggestChangeScreen(),
    reviewSuggestions: (_) => const ReviewSuggestionsScreen(),
    voteActivity: (_) => const VoteActivityScreen(),
    expenses: (_) => const ExpensesScreen(),
  };

  static List<String> get all => table.keys.toList();
}
