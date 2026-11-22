import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/trip_repository.dart';
import 'features/expenses/data/expense_repository.dart';
import 'features/expenses/data/in_memory_expense_repository.dart';
import 'routes.dart';

class TripSyncApp extends StatelessWidget {
  final TripRepository repository;
  final AuthService auth;
  final ExpenseRepository expenseRepository;

  /// Defaults to in-memory fakes so tests don't need Firebase.
  TripSyncApp({
    super.key,
    required this.repository,
    AuthService? auth,
    ExpenseRepository? expenseRepository,
  }) : auth = auth ?? AuthService(),
       expenseRepository = expenseRepository ?? InMemoryExpenseRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: auth),
        Provider<TripRepository>.value(value: repository),
        Provider<ExpenseRepository>.value(value: expenseRepository),
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
