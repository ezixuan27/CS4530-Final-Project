import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

class ReviewSuggestionsScreen extends StatelessWidget {
  const ReviewSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Review Suggestions',
      story: 'Story 5 · Approve / decline suggestions',
      owner: 'Member B',
      actions: [],
    );
  }
}
