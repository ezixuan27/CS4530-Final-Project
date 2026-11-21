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

- **Database: Firebase.** The setup isn't decided yet. Because Views and ViewModels only use repository interfaces, switching means writing a Firebase version of each repository (e.g. `FirebaseTripRepository`) and swapping it in `main.dart`. Views and ViewModels stay unchanged. Member A sets up the shared Firebase project and Firebase Auth (which replaces the `AuthService` stub), and each member writes the Firebase version of their own repository (see "Who owns what").
- **Routing:** built-in named routes for now. Consider `go_router` if we need auth redirects once Firebase Auth is in.

## Who owns what

Each member owns their features end to end: screen, ViewModel, repository, and the database reads/writes behind it. Member A also connects the app to the shared backend.

| Member | Stories | Folders |
|---|---|---|
| Rose | 1 Account access, 2 Create and invite, 3 Join a trip, 6 Reopen the plan (My Trips) + backend setup | `features/auth/`, `features/trips/`, `data/` |
| Marina | 4 Suggest a change, 5 Manage the itinerary (incl. the itinerary view reached from My Trips) | `features/itinerary/` |
| Ella | 7 Choose an activity, 8 Track expenses | `features/voting/`, `features/expenses/` |

**Agree on these first:** once a trip is open, every module gets the same three things. Until A's backend is ready, B and C can build against the in-memory fakes with these values.

- `currentUserId`: `AuthService.currentUser.id`
- `tripId`: the route argument (`ModalRoute.of(context)!.settings.arguments as String`)
- the user's role in the trip: organizer if `trip.organizerId == currentUserId`, otherwise member

**10-second sync (NFR):** "Each saved change must appear on every other trip member's device within 10 seconds." With Firestore this is mostly free *if* screens listen for live updates (`snapshots()` → `Stream`) instead of loading once (`get()`). Each owner does this for their own data and checks it with two devices or emulators.

Listening is cheap. Firestore bills per document *read*, not per minute: the first snapshot reads the matching documents once, then each change costs one read per listener. That's far cheaper than re-fetching with `get()` every few seconds, and a class project stays well inside the free tier. To avoid wasted reads:

- Start the listener in the ViewModel, once. Never in `build()`, which runs on every rebuild.
- Cancel the subscription in the ViewModel's `dispose()`.
- Listen only to this trip's data (e.g. `trips/{tripId}/expenses`), not a whole top-level collection.

### Rose · Accounts, trips, backend

**Story 1 · Account access.** *Purpose:* only signed-in travelers can see their trips.
- Register with email + password, sign in, sign out. Show loading and error states (wrong password, email already used).
- [ ] `AuthService`: replace the stub with real register / sign in / sign out / `currentUser`
- [ ] `AuthViewModel` + Sign In / Register views with form validation and error messages
- [ ] Signed-out users can't reach trip screens

**Story 2 · Create and invite.** *Purpose:* an organizer starts a trip and shares one code instead of adding people manually.
- Form for trip name, destination, start and end dates. On save, show the generated invite code (e.g. `RME27A`) with a copy button. The creator becomes the organizer.
- [ ] `CreateTripViewModel` + view: validation (name required, end date not before start)
- [ ] Copy code to clipboard

**Story 3 · Join a trip.** *Purpose:* invited friends get into the group's plan with just the code.
- Enter a code, then join and land in the trip. Unknown code shows an error. Joining twice is harmless.
- [ ] `JoinTripViewModel` + view, using `TripRepository.joinTrip`

**Story 6 · Reopen the plan (My Trips).** *Purpose:* next morning, a member finds their trip again without scrolling the group chat.
- List of the user's trips. Tapping one opens that trip's itinerary (built by B) with the real `tripId`.
- [x] `MyTripsViewModel` + view (reference MVVM example)
- [ ] Trip overview with entries to Itinerary, Polls, Expenses

**Backend setup.**
- [ ] Create the Firebase project, add `firebase_core`, initialize in `main.dart`
- [ ] `FirestoreTripRepository` implementing `TripRepository`. Store roles (organizer / member).
- [ ] Provide every repository in `app.dart`. Write a short "how to add your Firestore repository" note for B and C.

### Marina · Itinerary and suggestions

**Story 5 · Manage the itinerary.** *Purpose:* the organizer keeps one agreed plan everyone follows.
- Everyone sees the itinerary: items with title, time, place (e.g. "Colosseum · 9 AM · North gate"). The organizer can add, edit, and delete items and approve or decline suggestions.
- [ ] `ItineraryRepository` (interface + in-memory fake) in `features/itinerary/data/`
- [ ] `ItineraryViewModel` + view: list items for `tripId`, organizer-only Edit
- [ ] Review suggestions view: Approve updates the item and marks the request approved *in one operation*. Decline only marks it declined.

**Story 4 · Suggest a change.** *Purpose:* members propose fixes (a better meeting point) without editing the plan themselves.
- A member picks an item, enters the proposed value, and sees it as "Pending". The official itinerary keeps the old value until the organizer approves. Example: Ben suggests North gate, everyone still sees South gate, and after Approve everyone sees North gate.
- [ ] Suggest change view + ViewModel, using `ChangeRequest`
- [ ] Show pending / approved / declined status

**Shared with backend.**
- [ ] `FirestoreItineraryRepository` with live updates
- [ ] Firestore rules: only the organizer can edit the itinerary and approve or decline

### Ella · Polls and expenses

**Story 7 · Choose an activity.** *Purpose:* the group sees which activity people prefer, not 40 chat messages.
- The organizer posts a poll with options (e.g. Vatican Museums, Cooking class). Members pick one and vote, and can see the results.
- [ ] `PollRepository` (interface + in-memory fake) in `features/voting/data/`
- [ ] `PollViewModel` + view: create poll (organizer), vote (one vote per member, can change it), show counts

**Story 8 · Track expenses.** *Purpose:* everyone can see who paid for what.
- Add an expense with description, amount, and payer, and show a list like "Tickets · €48 · Paid by Ben". Amounts are integer cents. No splitting or who-owes-whom (not in the FR).
- [ ] `ExpenseRepository` (interface + in-memory fake) in `features/expenses/data/`
- [ ] `ExpenseViewModel` + view: add form (amount > 0, description required), list for `tripId`

**Shared with backend.**
- [ ] `FirestorePollRepository`, `FirestoreExpenseRepository` with live updates
- [ ] Firestore rules: only the organizer posts polls. Members of the trip can vote and add expenses.

Shared files (`routes.dart`, `models/`, `data/`): keep changes small and mention them in your PR.
