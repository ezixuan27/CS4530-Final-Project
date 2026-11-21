# TripSync — Group Travel Planner

Trip details get buried in the group chat. TripSync keeps a group's trip, itinerary, votes, and shared expenses in one place.

## Run

```bash
flutter pub get
flutter run
flutter test
dart analyze   # `flutter analyze` crashes when the project path has non-ASCII characters
```

## Structure (MVVM)

```
lib/
  main.dart                 # entry point, picks the repository implementation
  app.dart                  # MaterialApp, theme, app-wide providers (AuthService, TripRepository)
  routes.dart               # all route names + route table
  models/                   # plain data classes (fields only)
  data/                     # shared Model layer
    auth_service.dart               # current signed-in user (stub: test user)
    trip_repository.dart            # trips: create / join / look up
    in_memory_trip_repository.dart  # temporary fake (no database yet)
  widgets/placeholder_screen.dart   # temporary scaffold; replace as you build
  features/<feature>/
    views/                  # screens (View)
    view_models/            # ChangeNotifier per screen (ViewModel)
    data/                   # this feature's repository, if it needs one (Model)
```

**The rule for each layer** (see `features/trips/` for a working example):

- **View** (`views/`): builds widgets from ViewModel state and forwards taps to it. No data loading or business logic. Create the ViewModel with `ChangeNotifierProvider` and read it with `context.watch<XViewModel>()`.
- **ViewModel** (`view_models/`): a `ChangeNotifier` that loads data from repositories, holds the screen's state, handles user actions, and calls `notifyListeners()`. No widgets or `BuildContext`, so it can be unit tested without a UI.
- **Model** (`models/`, `data/`, `features/<feature>/data/`): data classes plus repositories that read and write it. Repositories are interfaces with an in-memory fake for now.

Placeholder screens don't have a ViewModel yet. Add one when you build the screen, plus a test in `test/features/<feature>/`.

**Conventions:**

- Get the signed-in user from `AuthService.currentUser` (pass `AuthService` into your ViewModel). It's a stub that always returns a test user until real sign-in is built (Member A). Don't hardcode user ids.
- Trip-scoped screens get the trip id as the route argument:
  `Navigator.pushNamed(context, Routes.itinerary, arguments: tripId)`.
- `TripRepository` covers trips only. For itinerary, polls, or expenses, add your own repository (interface + in-memory fake) in `features/<feature>/data/`, e.g. `features/expenses/data/expense_repository.dart`, and register its provider in `app.dart`. That way we don't all edit the same file.
- Money is stored as integer cents (`Expense.amountInCents`), not `double`.

## Decided, not done yet

- **Database: Firebase.** The setup isn't decided yet. Because Views and ViewModels only use repository interfaces, switching means writing a Firebase version of each repository (e.g. `FirebaseTripRepository`) and swapping it in `main.dart`. Views and ViewModels stay unchanged. Suggested split: Member A sets up the shared Firebase project and Firebase Auth (which replaces the `AuthService` stub), and each member writes the Firebase version of their own repository. For the 10-second sync NFR, repositories will probably expose Firestore streams.
- **Routing:** built-in named routes for now. Consider `go_router` if we need auth redirects once Firebase Auth is in.

## Who owns what

| Member | Stories | Files |
|---|---|---|
| A | 1 Account access, 2 Create and invite, 3 Join a trip | `features/auth/`, Create / Join Trip in `features/trips/` |
| B | 4 Suggest a change, 5 Manage the itinerary, 6 Reopen the plan | `features/itinerary/`, My Trips in `features/trips/` |
| C | 7 Choose an activity, 8 Track expenses, sync across devices within 10 seconds (NFR) | `features/voting/`, `features/expenses/` |

Shared files (`routes.dart`, `models/`, `data/`): keep changes small and mention them in your PR.
