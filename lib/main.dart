import 'package:flutter/material.dart';

import 'app.dart';
import 'data/in_memory_trip_repository.dart';

void main() {
  // Swap InMemoryTripRepository for a database-backed one later.
  runApp(TripSyncApp(repository: InMemoryTripRepository()));
}
