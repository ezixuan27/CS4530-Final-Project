import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/repositories.dart';
import 'data/trip_repository.dart';
import 'routes.dart';

class TripSyncApp extends StatelessWidget {
  final Repositories repositories;
  final AuthService auth;

  /// Without [repositories], every repository is the in-memory version
  /// (what tests want). `main.dart` passes `Repositories.firestore()`.
  TripSyncApp({super.key, Repositories? repositories, AuthService? auth})
    : repositories = repositories ?? Repositories(),
      auth = auth ?? AuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // One line per repository. Screens read them with
      // context.read<XRepository>().
      providers: [
        Provider<AuthService>.value(value: auth),
        Provider<TripRepository>.value(value: repositories.trips),
        // Provider<ExpenseRepository>.value(value: repositories.expenses),
      ],
      child: MaterialApp(
        title: 'TripSync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: Routes.signIn,
        routes: Routes.table,
      ),
    );
  }
}
