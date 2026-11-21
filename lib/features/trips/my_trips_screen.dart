import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../data/trip_repository.dart';
import '../../models/trip.dart';
import '../../routes.dart';

/// Story 6 · Reopen the plan (Member B).
/// Lists the trips the signed-in user created or joined. Minimal version:
/// Member B owns the real design.
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  late Future<List<Trip>> _trips;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = context.read<AuthService>().currentUser.id;
    _trips = context.read<TripRepository>().tripsForUser(userId);
  }

  /// Opens [route] and reloads the list when the user comes back,
  /// so a trip created or joined there shows up.
  Future<void> _openAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: FutureBuilder<List<Trip>>(
              future: _trips,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trips = snapshot.data!;
                if (trips.isEmpty) {
                  return const Center(
                    child: Text(
                      'No trips yet. Create one or join with a code.',
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final trip in trips)
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
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openAndRefresh(Routes.createTrip),
                    child: const Text('Create Trip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openAndRefresh(Routes.joinTrip),
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
}
