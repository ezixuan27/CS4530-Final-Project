import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../widgets/placeholder_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Register',
      story: 'Story 1 · Account access',
      owner: 'Member A',
      actions: [
        PlaceholderAction('Create account', Routes.myTrips, replace: true),
      ],
    );
  }
}
