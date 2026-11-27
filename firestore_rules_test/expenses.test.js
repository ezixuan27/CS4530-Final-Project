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
  updateDoc,
} from 'firebase/firestore';
import { MEM, ORG, OUT, TRIP, as, seed, seedTrip, setup } from './helpers.js';

const env = await setup();
after(() => env.cleanup());

const EXPENSES = `trips/${TRIP}/expenses`;

const expense = (uid) => doc(as(env, uid), `${EXPENSES}/e1`);
const expenses = (uid) => collection(as(env, uid), EXPENSES);

/** What ExpenseRepository.addExpense writes for MEM, with overrides. */
const newExpense = (overrides = {}) => ({
  description: 'Dinner',
  amountInCents: 3050,
  paidBy: MEM,
  paidByName: 'Mia',
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('expenses', () => {
  beforeEach(async () => {
    await env.clearFirestore();
    await seedTrip(env, TRIP, { organizerId: ORG, memberIds: [ORG, MEM] });
    await seed(env, `${EXPENSES}/e1`, {
      description: 'Tickets',
      amountInCents: 4800,
      paidBy: MEM,
      paidByName: 'Mia',
      createdAt: Timestamp.fromDate(new Date('2026-11-23T10:00:00Z')),
    });
  });

  describe('read', () => {
    test('member can read', async () => {
      await assertSucceeds(getDoc(expense(ORG)));
    });

    test('non-member cannot read', async () => {
      await assertFails(getDoc(expense(OUT)));
    });

    test('signed-out user cannot read', async () => {
      await assertFails(getDoc(expense(null)));
    });
  });

  describe('create', () => {
    test('member adds an expense they paid', async () => {
      await assertSucceeds(addDoc(expenses(MEM), newExpense()));
    });

    test('non-member cannot add', async () => {
      await assertFails(addDoc(expenses(OUT), newExpense({ paidBy: OUT })));
    });

    test('cannot record someone else as the payer', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ paidBy: ORG })));
    });

    test('amount must be greater than 0', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ amountInCents: 0 })));
    });

    test('amount must be whole cents', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ amountInCents: 12.5 })));
    });

    test('description cannot be empty', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ description: '' })));
    });

    test('createdAt must be the server time', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ createdAt: Timestamp.now() })));
    });

    test('cannot add an extra field', async () => {
      await assertFails(addDoc(expenses(MEM), newExpense({ settled: true })));
    });

    test('signed-out user cannot add', async () => {
      await assertFails(addDoc(expenses(null), newExpense()));
    });

    test('all fields are required', async () => {
      const { paidByName, ...withoutName } = newExpense();
      await assertFails(addDoc(expenses(MEM), withoutName));
    });
  });

  describe('update', () => {
    test('payer edits description and amount', async () => {
      await assertSucceeds(
        updateDoc(expense(MEM), { description: 'Museum tickets', amountInCents: 5000 }),
      );
    });

    test('organizer who did not pay cannot edit', async () => {
      await assertFails(updateDoc(expense(ORG), { amountInCents: 1 }));
    });

    test('payer cannot change the payer', async () => {
      await assertFails(updateDoc(expense(MEM), { paidBy: ORG }));
    });

    test('payer cannot set the amount to 0', async () => {
      await assertFails(updateDoc(expense(MEM), { amountInCents: 0 }));
    });

    test('payer cannot empty the description', async () => {
      await assertFails(updateDoc(expense(MEM), { description: '' }));
    });

    test('payer cannot change paidByName or createdAt', async () => {
      await assertFails(updateDoc(expense(MEM), { paidByName: 'Someone else' }));
      await assertFails(updateDoc(expense(MEM), { createdAt: Timestamp.now() }));
    });

    test('non-member cannot edit', async () => {
      await assertFails(updateDoc(expense(OUT), { amountInCents: 1 }));
    });
  });

  describe('delete', () => {
    test('payer cannot delete', async () => {
      await assertFails(deleteDoc(expense(MEM)));
    });
  });
});
