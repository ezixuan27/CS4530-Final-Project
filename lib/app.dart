import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/trip_repository.dart';
import 'routes.dart';

class TripSyncApp extends StatelessWidget {
  final TripRepository repository;

  const TripSyncApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Provider<TripRepository>.value(
      value: repository,
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
