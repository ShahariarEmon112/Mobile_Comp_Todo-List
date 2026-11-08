// Tests for Firestore/firestore.rules using the Firestore emulator.
// Run with: npm test   (see README.md > "Testing the security rules")
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const RULES_PATH = fileURLToPath(new URL('../firestore.rules', import.meta.url));
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8085').split(':');

let env;

const ALICE = 'alice';
const BOB = 'bob';

function db(uid) {
  return uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
}

function taskRef(firestore, uid, taskId) {
  return doc(firestore, 'users', uid, 'tasks', taskId);
}

/** The exact document the iOS app writes on create. */
function newTask(uid, taskId, overrides = {}) {
  return {
    id: taskId,
    ownerId: uid,
    title: 'Finish lab report',
    description: 'Firestore section',
    isCompleted: false,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

/** Seeds a task with rules disabled, as if it had been created earlier. */
async function seedTask(uid, taskId) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(taskRef(context.firestore(), uid, taskId), {
      id: taskId,
      ownerId: uid,
      title: 'Seeded task',
      description: '',
      isCompleted: false,
      createdAt: Timestamp.fromDate(new Date('2026-01-01T10:00:00Z')),
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-todo-rules',
    firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host, port: Number(port) },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  await env?.cleanup();
});

describe('authentication', () => {
  test('signed-out users cannot read tasks', async () => {
    await seedTask(ALICE, 't1');
    await assertFails(getDoc(taskRef(db(null), ALICE, 't1')));
  });

  test('signed-out users cannot create tasks', async () => {
    await assertFails(setDoc(taskRef(db(null), ALICE, 't1'), newTask(ALICE, 't1')));
  });
});

describe('create', () => {
  test('owner can create a valid task', async () => {
    await assertSucceeds(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1')));
  });

  test('cannot create a task in another user\'s collection', async () => {
    await assertFails(setDoc(taskRef(db(BOB), ALICE, 't1'), newTask(ALICE, 't1')));
  });

  test('ownerId must match the path', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { ownerId: BOB })));
  });

  test('id field must match the document ID', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { id: 'other' })));
  });

  test('unknown fields are rejected', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { priority: 'high' })));
  });

  test('missing required fields are rejected', async () => {
    const task = newTask(ALICE, 't1');
    delete task.description;
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), task));
  });

  test('empty or blank titles are rejected', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { title: '' })));
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't2'), newTask(ALICE, 't2', { title: '   ' })));
  });

  test('titles over 120 characters are rejected', async () => {
    await assertSucceeds(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { title: 'a'.repeat(120) })));
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't2'), newTask(ALICE, 't2', { title: 'a'.repeat(121) })));
  });

  test('descriptions over 1000 characters are rejected', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { description: 'a'.repeat(1001) })));
  });

  test('field types are enforced', async () => {
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { isCompleted: 'yes' })));
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't2'), newTask(ALICE, 't2', { title: 42 })));
  });

  test('createdAt must be the server time', async () => {
    const past = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
    await assertFails(setDoc(taskRef(db(ALICE), ALICE, 't1'), newTask(ALICE, 't1', { createdAt: past })));
  });
});

describe('read', () => {
  test('owner can read a task and list their tasks in order', async () => {
    await seedTask(ALICE, 't1');
    await assertSucceeds(getDoc(taskRef(db(ALICE), ALICE, 't1')));
    const tasks = query(collection(db(ALICE), 'users', ALICE, 'tasks'), orderBy('createdAt', 'desc'));
    await assertSucceeds(getDocs(tasks));
  });

  test('other users cannot read or list someone else\'s tasks', async () => {
    await seedTask(ALICE, 't1');
    await assertFails(getDoc(taskRef(db(BOB), ALICE, 't1')));
    await assertFails(getDocs(collection(db(BOB), 'users', ALICE, 'tasks')));
  });
});

describe('update', () => {
  test('owner can edit title, description and completion (as the app does)', async () => {
    await seedTask(ALICE, 't1');
    await assertSucceeds(updateDoc(taskRef(db(ALICE), ALICE, 't1'), {
      title: 'Updated title',
      description: 'Updated description',
      isCompleted: true,
      updatedAt: serverTimestamp(),
    }));
  });

  test('owner can toggle completion (as the app does)', async () => {
    await seedTask(ALICE, 't1');
    await assertSucceeds(updateDoc(taskRef(db(ALICE), ALICE, 't1'), {
      isCompleted: true,
      updatedAt: serverTimestamp(),
    }));
  });

  test('updates must set updatedAt to the server time', async () => {
    await seedTask(ALICE, 't1');
    await assertFails(updateDoc(taskRef(db(ALICE), ALICE, 't1'), { isCompleted: true }));
  });

  test('id, ownerId and createdAt cannot change', async () => {
    await seedTask(ALICE, 't1');
    const ref = taskRef(db(ALICE), ALICE, 't1');
    await assertFails(updateDoc(ref, { ownerId: BOB, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { id: 'other', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });

  test('updates are validated like creates', async () => {
    await seedTask(ALICE, 't1');
    const ref = taskRef(db(ALICE), ALICE, 't1');
    await assertFails(updateDoc(ref, { title: '', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { extra: true, updatedAt: serverTimestamp() }));
  });

  test('other users cannot update someone else\'s task', async () => {
    await seedTask(ALICE, 't1');
    await assertFails(updateDoc(taskRef(db(BOB), ALICE, 't1'), { isCompleted: true, updatedAt: serverTimestamp() }));
  });
});

describe('delete', () => {
  test('owner can delete their task', async () => {
    await seedTask(ALICE, 't1');
    await assertSucceeds(deleteDoc(taskRef(db(ALICE), ALICE, 't1')));
  });

  test('other users cannot delete someone else\'s task', async () => {
    await seedTask(ALICE, 't1');
    await assertFails(deleteDoc(taskRef(db(BOB), ALICE, 't1')));
  });
});

describe('everything else is denied', () => {
  test('user profile documents are not writable', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users', ALICE), { name: 'Alice' }));
  });

  test('other top-level collections are denied', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'public', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db(ALICE), 'public', 'x')));
  });
});
