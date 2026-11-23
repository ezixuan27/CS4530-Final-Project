import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/in_memory_auth_service.dart';
import 'data/repositories.dart';
import 'data/trip_repository.dart';
import 'features/expenses/data/expense_repository.dart';
import 'features/voting/data/poll_repository.dart';
import 'routes.dart';

class TripSyncApp extends StatelessWidget {
  final Repositories repositories;
  final AuthService auth;

  /// Defaults are the in-memory versions for tests. main.dart passes the
  /// Firebase ones.
  TripSyncApp({super.key, Repositories? repositories, AuthService? auth})
    : repositories = repositories ?? Repositories(),
      auth = auth ?? InMemoryAuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // One line per repository. Screens read them with
      // context.read<XRepository>().
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<TripRepository>.value(value: repositories.trips),
        Provider<ExpenseRepository>.value(value: repositories.expenses),
        Provider<PollRepository>.value(value: repositories.polls),
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
