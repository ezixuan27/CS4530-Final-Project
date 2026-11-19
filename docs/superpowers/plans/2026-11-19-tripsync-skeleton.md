# TripSync Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clickable TripSync skeleton (placeholder screens for all 8 stories) that 3 teammates can split by feature folder.

**Architecture:** `provider` exposes a `TripRepository` (abstract) backed by `InMemoryTripRepository`. Screens live in `lib/features/<feature>/`, routes in `lib/routes.dart` via `MaterialApp.routes` / `onGenerateRoute`.

**Tech Stack:** Flutter 3.47, Dart ^3.13, provider.

**Spec:** `docs/superpowers/specs/2026-11-19-tripsync-skeleton-design.md`

## Global Constraints

- No database; data is in memory only.
- Only new dependency: `provider`.
- Theme seed color: deep purple (matches the user-story art).
- Work on branch `ella`; commit locally, do not push; no AI attribution in commit messages.

## Review Focus

- Every route name in `Routes` resolves to a screen (no "route not found" crash) — covered by the route test in Task 3.
- Screens that need a trip receive `tripId` as a route argument, not a global — checked in review.

---

### Task 1: Models + repository

**Files:**
- Create: `lib/models/{user,trip,itinerary_item,change_request,activity_poll,expense}.dart`
- Create: `lib/data/trip_repository.dart`, `lib/data/in_memory_trip_repository.dart`
- Test: `test/data/in_memory_trip_repository_test.dart`

**Interfaces — Produces:**
- `AppUser(id, name, email)`; `Trip(id, name, destination, startDate, endDate, inviteCode, organizerId, memberIds)`; `ItineraryItem(id, tripId, title, time, meetingPoint)`; `ChangeRequest(id, itemId, proposedBy, proposedMeetingPoint, status: ChangeStatus{pending,approved,declined})`; `ActivityPoll(id, tripId, options: List<String>, votes: Map<userId, option>)`; `Expense(id, tripId, description, amount, paidBy)`.
- `abstract class TripRepository { Future<List<Trip>> tripsForUser(String userId); Future<Trip> createTrip(...); Future<Trip?> joinTrip(String code, String userId); Future<Trip?> tripById(String id); }` — other members add methods as they build.

- [ ] Test: `createTrip` returns a trip with a 6-char invite code; `joinTrip(code, 'u2')` adds `u2` to `memberIds`; `joinTrip('BAD', ...)` returns null.
- [ ] Run, see fail; implement; run, see pass; commit.

### Task 2: App shell, theme, placeholder screens

**Files:**
- Modify: `lib/main.dart` (replace counter demo)
- Create: `lib/app.dart`, `lib/routes.dart`, `lib/widgets/placeholder_screen.dart`
- Create screens: `features/auth/{sign_in,register}_screen.dart`, `features/trips/{my_trips,create_trip,join_trip}_screen.dart`, `features/itinerary/{itinerary,suggest_change,review_suggestions}_screen.dart`, `features/voting/vote_activity_screen.dart`, `features/expenses/expenses_screen.dart`
- Modify: `pubspec.yaml` (add provider)

- `PlaceholderScreen(title, story, owner, actions: List<(String label, String route)>)` renders title, "Story N · Owner X · TODO", and buttons navigating onward.
- Flow: SignIn → MyTrips → {CreateTrip, JoinTrip, Itinerary(tripId)}; Itinerary → {SuggestChange, ReviewSuggestions, VoteActivity, Expenses}.

### Task 3: Tests, README, verify

**Files:** Replace `test/widget_test.dart`; modify `README.md`.

- [ ] Smoke test: app starts on "Sign In"; tapping through Sign In → My Trips shows "My Trips".
- [ ] Route test: pumping each `Routes` name renders without exception.
- [ ] README: story → owner → folder table.
- [ ] `flutter analyze` → "No issues found!"; `flutter test` → all pass; commit.
