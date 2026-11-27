import { after, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc } from 'firebase/firestore';
import { MEM, ORG, TRIP, as, seedTrip, setup } from './helpers.js';

const env = await setup();
after(() => env.cleanup());

const poll = (uid) => doc(as(env, uid), `trips/${TRIP}/polls/p1`);

describe('polls', () => {
  beforeEach(async () => {
    await env.clearFirestore();
    await seedTrip(env, TRIP, { organizerId: ORG, memberIds: [ORG, MEM] });
  });

  test('signed-out user cannot read polls', async () => {
    await assertFails(getDoc(poll(null)));
  });

  test('member can read polls', async () => {
    await assertSucceeds(getDoc(poll(MEM)));
  });
});
