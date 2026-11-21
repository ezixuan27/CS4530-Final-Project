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
  app.dart                  # MaterialApp, theme, providers (AuthService, TripRepository)
  routes.dart               # all route names + route table
  models/                   # plain data classes (fields only)
  data/
    auth_service.dart               # current signed-in user (stub: test user)
    trip_repository.dart            # trips: create / join / look up
    in_memory_trip_repository.dart  # temporary fake (no database yet)
  widgets/placeholder_screen.dart   # temporary scaffold; replace as you build
  features/<feature>/       # one folder per feature, screens live here
```

- Get the signed-in user with `context.read<AuthService>().currentUser`. It's a stub that always returns a test user until real sign-in is built (Member A). Don't hardcode user ids in screens.
- Get the trip repository with `context.read<TripRepository>()`.
- Trip-scoped screens get the trip id as the route argument:
  `Navigator.pushNamed(context, Routes.itinerary, arguments: tripId)`.
- `TripRepository` covers trips only. For itinerary, polls, or expenses, add your own repository (interface + in-memory fake) in your feature folder, e.g. `features/expenses/expense_repository.dart`, and register its provider in `app.dart`. That way we don't all edit the same file.
- Money is stored as integer cents (`Expense.amountInCents`), not `double`.

## Who owns what

| Member | Stories | Files |
|---|---|---|
| A | 1 Account access, 2 Create and invite, 3 Join a trip | `features/auth/*`, `features/trips/create_trip_screen.dart`, `features/trips/join_trip_screen.dart` |
| B | 4 Suggest a change, 5 Manage the itinerary, 6 Reopen the plan | `features/itinerary/*`, `features/trips/my_trips_screen.dart` |
| C | 7 Choose an activity, 8 Track expenses, sync across devices within 10 seconds (NFR) | `features/voting/*`, `features/expenses/*` |

Shared files (`routes.dart`, `models/`, `data/`): keep changes small and mention them in your PR.
