# TripSync — Group Travel Planner

Trip details get buried in the group chat. TripSync keeps a group's trip, itinerary, votes, and shared expenses in one place.

## Run

```bash
flutter pub get
flutter run
flutter test
dart analyze   # `flutter analyze` crashes when the project path has non-ASCII characters
```

## Structure

```
lib/
  main.dart                 # entry point, picks the repository implementation
  app.dart                  # MaterialApp, theme, Provider<TripRepository>
  routes.dart               # all route names + route table
  models/                   # plain data classes (fields only)
  data/
    trip_repository.dart            # interface screens depend on
    in_memory_trip_repository.dart  # temporary fake (no database yet)
  widgets/placeholder_screen.dart   # temporary scaffold; replace as you build
  features/<feature>/       # one folder per feature, screens live here
```

- Get the repository in a screen with `context.read<TripRepository>()`.
- Trip-scoped screens get the trip id as the route argument:
  `Navigator.pushNamed(context, Routes.itinerary, arguments: tripId)`.
- Need a new data operation? Add it to `TripRepository`, then implement it in `InMemoryTripRepository`.

## Who owns what

| Member | Stories | Files |
|---|---|---|
| A | 1 Account access, 2 Create and invite, 3 Join a trip | `features/auth/*`, `features/trips/create_trip_screen.dart`, `features/trips/join_trip_screen.dart` |
| B | 4 Suggest a change, 5 Manage the itinerary, 6 Reopen the plan | `features/itinerary/*`, `features/trips/my_trips_screen.dart` |
| C | 7 Choose an activity, 8 Track expenses, offline save/retry requirement | `features/voting/*`, `features/expenses/*` |

Shared files (`routes.dart`, `models/`, `data/`): keep changes small and mention them in your PR.
