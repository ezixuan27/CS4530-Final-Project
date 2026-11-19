import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

class SuggestChangeScreen extends StatelessWidget {
  const SuggestChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Suggest Change',
      story: 'Story 4 · Suggest a change',
      owner: 'Member B',
      actions: [],
    );
  }
}
