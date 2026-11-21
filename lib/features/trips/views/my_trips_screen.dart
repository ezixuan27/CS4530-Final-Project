import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../routes.dart';
import '../view_models/my_trips_view_model.dart';

/// Story 6 · Reopen the plan (Member A).
/// Lists the trips the signed-in user created or joined.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyTripsViewModel(
        repository: context.read<TripRepository>(),
        auth: context.read<AuthService>(),
      )..load(),
      child: const _MyTripsView(),
    );
  }
}

class _MyTripsView extends StatelessWidget {
  const _MyTripsView();

  /// Opens [route] and reloads when the user comes back,
  /// so a trip created or joined there shows up.
  Future<void> _openAndRefresh(BuildContext context, String route) async {
    final vm = context.read<MyTripsViewModel>();
    await Navigator.pushNamed(context, route);
    await vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyTripsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.signIn,
              (_) => false,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildList(context, vm)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        _openAndRefresh(context, Routes.createTrip),
                    child: const Text('Create Trip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openAndRefresh(context, Routes.joinTrip),
                    child: const Text('Join Trip'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, MyTripsViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.trips.isEmpty) {
      return const Center(
        child: Text('No trips yet. Create one or join with a code.'),
      );
    }
    return ListView(
      children: [
        for (final trip in vm.trips)
          ListTile(
            title: Text(trip.name),
            subtitle: Text(trip.destination),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(
              context,
              Routes.itinerary,
              arguments: trip.id,
            ),
          ),
      ],
    );
  }
}
