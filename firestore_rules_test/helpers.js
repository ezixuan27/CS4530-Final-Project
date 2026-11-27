// Shared setup for the Firestore rules tests.
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';

export const ORG = 'org'; // the trip's organizer
export const MEM = 'mem'; // a member of the trip
export const OUT = 'out'; // signed in, but not in the trip
export const TRIP = 'trip1';

/** A test environment that loads ../firestore.rules into the emulator. */
export function setup() {
  return initializeTestEnvironment({
    projectId: 'demo-tripsync',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
}

/** Writes [data] at [path] with the rules turned off. */
export async function seed(env, path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

/** Seeds trips/{tripId} with the fields the rules read. */
export function seedTrip(env, tripId, { organizerId, memberIds }) {
  return seed(env, `trips/${tripId}`, { name: 'Rome', organizerId, memberIds });
}

/** Display names on each test user's sign-in token (Firebase Auth `name`). */
export const NAMES = { [ORG]: 'Olivia', [MEM]: 'Mia', [OUT]: 'Oscar' };

/**
 * A Firestore client signed in as [uid], or signed out when uid is null.
 * [token] overrides the sign-in token claims; by default the user has the
 * display name from NAMES.
 */
export function as(env, uid, token = { name: NAMES[uid] }) {
  const ctx = uid == null ? env.unauthenticatedContext() : env.authenticatedContext(uid, token);
  return ctx.firestore();
}
