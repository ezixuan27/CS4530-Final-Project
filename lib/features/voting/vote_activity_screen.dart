import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

class VoteActivityScreen extends StatelessWidget {
  const VoteActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Vote for an Activity',
      story: 'Story 7 · Choose an activity',
      owner: 'Member C',
      actions: [],
    );
  }
}
