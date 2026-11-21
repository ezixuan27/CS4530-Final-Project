import 'package:flutter/material.dart';

import '../../../widgets/placeholder_screen.dart';

class JoinTripScreen extends StatelessWidget {
  const JoinTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Join Trip',
      story: 'Story 3 · Join a trip',
      owner: 'Member A',
      actions: [],
    );
  }
}
