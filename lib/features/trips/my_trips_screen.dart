import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../widgets/placeholder_screen.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'My Trips',
      story: 'Story 6 · Reopen the plan',
      owner: 'Member B',
      actions: [
        PlaceholderAction('Create Trip', Routes.createTrip),
        PlaceholderAction('Join Trip', Routes.joinTrip),
        PlaceholderAction(
          'Open Itinerary (sample)',
          Routes.itinerary,
          arguments: 'trip1',
        ),
        PlaceholderAction('Sign Out', Routes.signIn, replace: true),
      ],
    );
  }
}
