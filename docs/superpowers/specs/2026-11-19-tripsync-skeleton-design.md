# TripSync skeleton — design (short)

**Intent:** Give a 3-person team a Flutter skeleton for TripSync (group travel planner, 8 user stories in `Week 10 Final User Story.png`) so each member can claim stories and fill in their own pages without merge conflicts. No database yet.

**Goals:** feature-folder structure, purple theme, named routes, model classes (fields only), an abstract `TripRepository` + in-memory fake, placeholder screens for every story wired so the flow is clickable end to end, README with the split, a passing smoke test.

**Non-goals:** real auth, persistence, business logic, offline retry (owned later by member C).

**Approaches considered:**
- provider + built-in named routes — **picked**: minimal deps, common in coursework.
- Riverpod / Bloc — rejected, too heavy for a 3-person course project.
- go_router — rejected for now, one fewer dependency; can be swapped later.

**Split:** A = stories 1–3 (auth, create, join); B = 4–6 (suggest, manage itinerary, my trips); C = 7–8 + offline NFR.

**Left to the builders:** all screen content, validation, real data layer.

Work happens on branch `ella`, committed locally, not pushed.
