import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/trip_repository.dart';
import 'routes.dart';

class TripSyncApp extends StatelessWidget {
  final TripRepository repository;
  final AuthService auth;

  TripSyncApp({super.key, required this.repository, AuthService? auth})
    : auth = auth ?? AuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: auth),
        Provider<TripRepository>.value(value: repository),
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
