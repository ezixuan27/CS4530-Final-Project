import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/auth_service.dart';
import 'package:final_project/data/in_memory_auth_service.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Fills in the Sign In form as the test user and submits it.
Future<void> signInAsTestUser(WidgetTester tester) async {
  await tester.enterText(field('Email'), AuthService.testUser.email);
  await tester.enterText(field('Password'), InMemoryAuthService.testPassword);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
  await tester.pumpAndSettle();
}
