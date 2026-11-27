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
  app.dart                  # MaterialApp, theme, provides AuthService + every repository
  routes.dart               # all route names + route table
  models/                   # plain data classes (fields only)
  data/                     # shared Model layer
    auth_service.dart               # sign in / register / sign out + current user
    firebase_auth_service.dart      # real version (Firebase Auth), used by the app
    in_memory_auth_service.dart     # in-memory version, used by tests
    repositories.dart               # every repository in one object (Firestore or in-memory)
    trip_repository.dart            # trips: create / join / look up / watch
    firestore_trip_repository.dart  # real version, used by the app
    in_memory_trip_repository.dart  # in-memory version, used by tests
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

- Get the signed-in user from `AuthService.currentUser` (pass `AuthService` into your ViewModel). Don't hardcode user ids.
- Trip-scoped screens get the trip id as the route argument:
  `Navigator.pushNamed(context, Routes.itinerary, arguments: tripId)`.
- `TripRepository` covers trips only. For itinerary, polls, or expenses, add your own repository in `features/<feature>/data/`, e.g. `features/expenses/data/expense_repository.dart`. See "Adding your Firestore repository" below.
- Money is stored as integer cents (`Expense.amountInCents`), not `double`.

## Firebase

The app is connected to the **CS4530FinalProject** Firebase project (iOS only). `main.dart` initializes Firebase and uses `FirestoreTripRepository`. Tests build `TripSyncApp` with in-memory repositories, so they never touch the database.

**Firestore layout** (add your collections here when you write your repository):

```
trips/{tripId}                        name, destination, startDate, endDate (Timestamp),
                                      inviteCode, organizerId, memberIds, createdAt
trips/{tripId}/expenses/{expenseId}   description, amountInCents, paidBy, paidByName,
                                      createdAt
trips/{tripId}/polls/{pollId}         question, options, votes {userId: option},
                                      createdBy, createdAt
inviteCodes/{code}                    tripId    # lets a non-member turn a code into a trip id
```

**Roles:** `organizerId` is the trip's organizer; `memberIds` is everyone in the trip, organizer included. Check a role with `trip.roleOf(currentUserId)`, which returns `TripRole.organizer`, `TripRole.member`, or `null` if the user isn't in the trip.

**Sign in:** the app uses Firebase Auth (email + password). Accounts show up in the Firebase console under **Authentication → Users**, and each user's id there is what goes in `memberIds` / `organizerId`. Data made before sign in existed (e.g. trips added by hand with `memberIds: ["u1"]`) won't show up for real accounts; add your **User UID** to `memberIds` in the console if you need it.

If you add a trip by hand in the console, also add a doc to `inviteCodes` (the code as the ID, with a `tripId` field), otherwise no one can join it with the code.

Firestore is still in test mode (open to anyone, expires around Dec 21). Real rules are being written in `firestore.rules` (see "Firestore rules" below).

**Testing with sign in:**
- `TripSyncApp()` and `InMemoryAuthService()` start signed in as `AuthService.testUser` (`u1`), so the app opens on My Trips and your ViewModels get a user.
- `InMemoryAuthService.signedOut()` starts signed out, e.g. `TripSyncApp(auth: InMemoryAuthService.signedOut())`. The test user's password is `InMemoryAuthService.testPassword`; `signInAsTestUser(tester)` in `test/test_helpers.dart` fills in the form.
- Signed out, every screen except Sign In and Register shows Sign In instead (`Routes.public` in `routes.dart`). If you add a screen people should reach without an account, add it there.

### Firestore rules

`firestore.rules` (repo root) decides who can read and write what. The app's own checks (e.g. "only the organizer creates polls") can be bypassed by anyone calling Firestore directly; the rules can't.

**Not published yet.** Rules are OR-ed: while the test-mode rule ("allow everything until Dec 21") is live, ours change nothing. Publishing only part of the file would block everything without a rule (e.g. reading `trips`) and break the app. Once every section is written and tested, one person pastes the whole file into Firebase Console → Firestore Database → Rules and clicks **Publish**, replacing the test-mode rule.

| Section | Owner | Status |
|---|---|---|
| Helpers `isMember(tripId)`, `isOrganizer(tripId)` | (shared) | done, same logic as `Trip.roleOf` |
| `polls`, `expenses` | Ella | done, tested |
| `trips`, `inviteCodes` | Rose | TODO: non-members read `inviteCodes/{code}`, users add only themselves to `memberIds` |
| itinerary, suggestions | Marina | TODO |

**Run the tests** (Firestore emulator + Node; no Firebase login needed):
```sh
cd firestore_rules_test
npm install            # once
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" npm test
```
The emulator needs Java. Android Studio ships one; the `JAVA_HOME` above points at it (or use any JDK 21+ you already have on your `PATH`).

**Adding your section:** add a `match` block inside `match /trips/{tripId}` (or next to it for top-level collections), reuse `isMember` / `isOrganizer`, and add a `<x>.test.js` file in `firestore_rules_test/` (copy `polls.test.js`). Test both what should be allowed and what should be denied: a rule that denies everything also passes the "denied" tests. Write test data the same way your Firestore repository does (e.g. `serverTimestamp()` for `createdAt`), so the rules are checked against what the app really sends.

### Adding your Firestore repository

**Copy the expenses feature.** `lib/features/expenses/` is a complete working example: repository, ViewModel, screen, and tests. Swap in your feature's names (`ItineraryRepository`, `PollRepository`, ...).

**1. Three files in `features/<feature>/data/`:**

| File | What it is | Expenses example |
|---|---|---|
| `<x>_repository.dart` | The interface. `Future` for actions, `Stream` for anything a screen shows, so it updates live (10-second sync). | `expense_repository.dart` |
| `in_memory_<x>_repository.dart` | Data in a list or map. Tests and `Repositories()` use it. | `in_memory_expense_repository.dart` |
| `firestore_<x>_repository.dart` | The real one. Store data under the trip (`trips/{tripId}/<x>`) so a listener only reads that trip. Convert Firestore maps to models inside this file; dates as `Timestamp`, money as `int` cents. | `firestore_expense_repository.dart` |

**2. Register it** in two places (copy the `expenses` lines):
- `lib/data/repositories.dart`: add a field, an in-memory default in the constructor, and the Firestore version in `Repositories.firestore()`.
- `lib/app.dart`: add `Provider<XRepository>.value(value: repositories.x)` to the providers list.

**3. Use it:** the view passes `context.read<XRepository>()` into its ViewModel. The ViewModel listens to the stream once and cancels in `dispose()`, like `ExpenseViewModel` (see "10-second sync" below).

**4. Test it:** `TripSyncApp()` and `Repositories()` use the in-memory versions by default. Pass your own to seed data, e.g. `TripSyncApp(repositories: Repositories(expenses: seededRepo))`. For the Firestore version, use `FakeFirebaseFirestore` like `test/features/expenses/expense_repository_test.dart`.

**5. Document it:** add your collection to the Firestore layout above.

## Decided, not done yet

- **Routing:** built-in named routes. The sign-in check lives in `app.dart` (`_route`), so we don't need `go_router` for now.

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
- the user's role in the trip: `trip.roleOf(currentUserId)` (`TripRole.organizer` or `TripRole.member`)

**10-second sync (NFR):** "Each saved change must appear on every other trip member's device within 10 seconds." With Firestore this is mostly free *if* screens listen for live updates (`snapshots()` → `Stream`) instead of loading once (`get()`). Each owner does this for their own data and checks it with two devices or emulators.

Listening is cheap. Firestore bills per document *read*, not per minute: the first snapshot reads the matching documents once, then each change costs one read per listener. That's far cheaper than re-fetching with `get()` every few seconds, and a class project stays well inside the free tier. To avoid wasted reads:

- Start the listener in the ViewModel, once. Never in `build()`, which runs on every rebuild.
- Cancel the subscription in the ViewModel's `dispose()`.
- Listen only to this trip's data (e.g. `trips/{tripId}/expenses`), not a whole top-level collection.

### Rose · Accounts, trips, backend

**Story 1 · Account access.** *Purpose:* only signed-in travelers can see their trips.
- Register with email + password, sign in, sign out. Show loading and error states (wrong password, email already used).
- [x] `AuthService`: replace the stub with real register / sign in / sign out / `currentUser`
- [x] `AuthViewModel` + Sign In / Register views with form validation and error messages
- [x] Signed-out users can't reach trip screens

**Story 2 · Create and invite.** *Purpose:* an organizer starts a trip and shares one code instead of adding people manually.
- Form for trip name, destination, start and end dates. On save, show the generated invite code (e.g. `RME27A`) with a copy button. The creator becomes the organizer.
- [x] `CreateTripViewModel` + view: validation (name required, end date not before start)
- [x] Copy code to clipboard

**Story 3 · Join a trip.** *Purpose:* invited friends get into the group's plan with just the code.
- Enter a code, then join and land in the trip. Unknown code shows an error. Joining twice is harmless.
- [x] `JoinTripViewModel` + view, using `TripRepository.joinTrip`

**Story 6 · Reopen the plan (My Trips).** *Purpose:* next morning, a member finds their trip again without scrolling the group chat.
- List of the user's trips. Tapping one opens that trip's itinerary (built by B) with the real `tripId`.
- [x] `MyTripsViewModel` + view (reference MVVM example)
- [ ] Trip overview with entries to Itinerary, Polls, Expenses

**Backend setup.**
- [x] Create the Firebase project, add `firebase_core`, initialize in `main.dart`
- [x] `FirestoreTripRepository` implementing `TripRepository`. Store roles (organizer / member).
- [ ] Tests for `FirestoreTripRepository` (e.g. with `fake_cloud_firestore`)
- [x] Provide every repository in `app.dart`. Write a short "how to add your Firestore repository" note for B and C.

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
- [x] `PollRepository` (interface + in-memory fake) in `features/voting/data/`
- [x] `PollViewModel` + view: create poll (organizer), vote (one vote per member, can change it), show counts
- [x] Edit a poll (organizer): change the question, rename options (votes kept), remove options (their votes deleted), add options

**Story 8 · Track expenses.** *Purpose:* everyone can see who paid for what.
- Add an expense with description, amount, and payer, and show a list like "Tickets · €48 · Paid by Ben". Amounts are integer cents. No splitting or who-owes-whom (not in the FR).
- [x] `ExpenseRepository` (interface + in-memory fake) in `features/expenses/data/`
- [x] `ExpenseViewModel` + view: add form (amount > 0, description required), list for `tripId`
- [x] Edit an expense (payer only): tap your own expense to change its description and amount

**Shared with backend.**
- [x] `FirestorePollRepository`, `FirestoreExpenseRepository` with live updates
- [ ] Firestore rules: only the organizer posts and edits polls. Members of the trip can vote and add expenses. Only the payer edits an expense.
  - Progress: polls + expenses rules written and tested in `firestore.rules`; publish pending (see "Firestore rules").

Shared files (`routes.dart`, `models/`, `data/`): keep changes small and mention them in your PR.
