import { after, beforeEach, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { MEM, ORG, OUT, TRIP, as, seed, seedTrip, setup } from './helpers.js';

const env = await setup();
after(() => env.cleanup());

const POLLS = `trips/${TRIP}/polls`;
const CREATED_AT = Timestamp.fromDate(new Date('2026-11-23T10:00:00Z'));
const storedPoll = {
  question: 'Q',
  options: ['A', 'B'],
  votes: {},
  createdBy: ORG,
  createdAt: CREATED_AT,
};

const poll = (uid) => doc(as(env, uid), `${POLLS}/p1`);
const polls = (uid) => collection(as(env, uid), POLLS);

/** What PollRepository.createPoll writes, with optional overrides. */
const newPoll = (overrides = {}) => ({
  question: 'Day 2 afternoon?',
  options: ['Vatican Museums', 'Cooking class'],
  votes: {},
  createdBy: ORG,
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('polls', () => {
  beforeEach(async () => {
    await env.clearFirestore();
    await seedTrip(env, TRIP, { organizerId: ORG, memberIds: [ORG, MEM] });
    await seed(env, `${POLLS}/p1`, storedPoll);
  });

  describe('read', () => {
    test('signed-out user cannot read', async () => {
      await assertFails(getDoc(poll(null)));
    });

    test('member can read', async () => {
      await assertSucceeds(getDoc(poll(MEM)));
    });

    test('non-member cannot read', async () => {
      await assertFails(getDoc(poll(OUT)));
    });

    test('organizer not listed in memberIds can still read', async () => {
      await seedTrip(env, TRIP, { organizerId: ORG, memberIds: [MEM] });
      await assertSucceeds(getDoc(poll(ORG)));
    });
  });

  describe('create', () => {
    test('organizer creates a valid poll', async () => {
      await assertSucceeds(addDoc(polls(ORG), newPoll()));
    });

    test('member cannot create a poll', async () => {
      await assertFails(addDoc(polls(MEM), newPoll({ createdBy: MEM })));
    });

    test('organizer cannot create as someone else', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ createdBy: MEM })));
    });

    test('organizer cannot create with 1 option', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ options: ['Only'] })));
    });

    test('organizer cannot create with votes already in', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ votes: { [MEM]: 'Cooking class' } })));
    });

    test('organizer cannot create with an extra field', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ closed: true })));
    });

    // The app parses options as List<String>; anything else would break
    // the poll list for the whole trip.
    test('options must be non-empty strings', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ options: [1, 2] })));
      await assertFails(addDoc(polls(ORG), newPoll({ options: ['A', null] })));
      await assertFails(addDoc(polls(ORG), newPoll({ options: ['A', ''] })));
    });

    test('options must be different', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ options: ['A', 'A'] })));
    });

    test('up to 20 options are allowed', async () => {
      const options = Array.from({ length: 20 }, (_, i) => `Option ${i + 1}`);
      await assertSucceeds(addDoc(polls(ORG), newPoll({ options })));
    });

    test('more than 20 options are denied', async () => {
      const options = Array.from({ length: 21 }, (_, i) => `Option ${i + 1}`);
      await assertFails(addDoc(polls(ORG), newPoll({ options })));
    });

    test('createdAt must be the server time', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ createdAt: Timestamp.now() })));
    });

    test('question cannot be empty', async () => {
      await assertFails(addDoc(polls(ORG), newPoll({ question: '' })));
    });

    test('all fields are required', async () => {
      const { votes, ...withoutVotes } = newPoll();
      await assertFails(addDoc(polls(ORG), withoutVotes));
    });
  });

  describe('update', () => {
    test('organizer edit via full-doc set is allowed', async () => {
      // What FirestorePollRepository.editPoll writes inside its transaction.
      await assertSucceeds(
        setDoc(poll(ORG), {
          ...storedPoll,
          question: 'Q2',
          options: ['A2', 'C'],
          votes: { [MEM]: 'A2' },
        }),
      );
    });

    test('organizer can vote', async () => {
      await assertSucceeds(updateDoc(poll(ORG), { [`votes.${ORG}`]: 'A' }));
    });

    test('member votes with a field-path update', async () => {
      await assertSucceeds(updateDoc(poll(MEM), { [`votes.${MEM}`]: 'A' }));
    });

    test('member changes their own vote', async () => {
      await seed(env, `${POLLS}/p1`, { ...storedPoll, votes: { [MEM]: 'A' } });
      await assertSucceeds(updateDoc(poll(MEM), { [`votes.${MEM}`]: 'B' }));
    });

    test('organizer cannot change createdBy', async () => {
      await assertFails(updateDoc(poll(ORG), { createdBy: MEM }));
    });

    test('organizer cannot change createdAt', async () => {
      await assertFails(updateDoc(poll(ORG), { createdAt: Timestamp.now() }));
    });

    test('organizer edit must keep a valid poll', async () => {
      await assertFails(updateDoc(poll(ORG), { options: ['A'] }));
      await assertFails(updateDoc(poll(ORG), { options: [1, 2] }));
      await assertFails(updateDoc(poll(ORG), { question: '' }));
    });

    test('member cannot change the question', async () => {
      await assertFails(updateDoc(poll(MEM), { question: 'Hacked' }));
    });

    test("member cannot set another user's vote", async () => {
      await assertFails(updateDoc(poll(MEM), { [`votes.${ORG}`]: 'A' }));
    });

    test('member cannot vote for an option not in the poll', async () => {
      await assertFails(updateDoc(poll(MEM), { [`votes.${MEM}`]: 'C' }));
    });

    test('non-member cannot vote', async () => {
      await assertFails(updateDoc(poll(OUT), { [`votes.${OUT}`]: 'A' }));
    });
  });

  describe('delete', () => {
    test('organizer cannot delete', async () => {
      await assertFails(deleteDoc(poll(ORG)));
    });

    test('member cannot delete', async () => {
      await assertFails(deleteDoc(poll(MEM)));
    });
  });
});
