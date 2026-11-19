import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../widgets/placeholder_screen.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripId = ModalRoute.of(context)?.settings.arguments as String?;
    return PlaceholderScreen(
      title: 'Itinerary',
      story: 'Stories 5 & 6 · Manage / reopen itinerary',
      owner: 'Member B',
      actions: [
        PlaceholderAction(
          'Suggest change',
          Routes.suggestChange,
          arguments: tripId,
        ),
        PlaceholderAction(
          'Review suggestions',
          Routes.reviewSuggestions,
          arguments: tripId,
        ),
        PlaceholderAction(
          'Vote for an activity',
          Routes.voteActivity,
          arguments: tripId,
        ),
        PlaceholderAction('Expenses', Routes.expenses, arguments: tripId),
      ],
    );
  }
}
