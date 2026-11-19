import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../widgets/placeholder_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Sign In',
      story: 'Story 1 · Account access',
      owner: 'Member A',
      actions: [
        PlaceholderAction('Sign In', Routes.myTrips, replace: true),
        PlaceholderAction('Register', Routes.register),
      ],
    );
  }
}
