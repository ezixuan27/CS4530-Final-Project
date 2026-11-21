import 'package:flutter/material.dart';

import '../../../widgets/placeholder_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Expenses',
      story: 'Story 8 · Track expenses',
      owner: 'Member C',
      actions: [],
    );
  }
}
