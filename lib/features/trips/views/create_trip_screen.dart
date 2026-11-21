import 'package:flutter/material.dart';

import '../../../widgets/placeholder_screen.dart';

class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Create Trip',
      story: 'Story 2 · Create and invite',
      owner: 'Member A',
      actions: [],
    );
  }
}
