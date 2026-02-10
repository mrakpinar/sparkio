// Usage:
// 1) Put your service account JSON somewhere safe (not in git) and set
//    FIREBASE_SERVICE_ACCOUNT=/full/path/to/serviceAccountKey.json
// 2) Fill tasks_durations.json next to this file: { "taskId": 6, ... }
// 3) npm install firebase-admin
// 4) node tools/update_task_durations.js

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const serviceAccountPath =
  process.env.FIREBASE_SERVICE_ACCOUNT ||
  path.resolve(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Missing service account JSON. Set FIREBASE_SERVICE_ACCOUNT.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

const payloadPath = path.resolve(__dirname, 'tasks_durations.json');
if (!fs.existsSync(payloadPath)) {
  console.error('Missing tasks_durations.json. Create it first.');
  process.exit(1);
}

/** Expected shape:
 * {
 *   "task_doc_id_1": { "durationMinutes": 6 },
 *   "task_doc_id_2": { "durationMinutes": 10, "difficulty": "medium" }
 * }
 */
const updates = JSON.parse(fs.readFileSync(payloadPath, 'utf8'));

async function run() {
  const entries = Object.entries(updates);
  if (!entries.length) {
    console.log('tasks_durations.json is empty; nothing to update.');
    return;
  }

  console.log(`Updating ${entries.length} tasks...`);
  const batchSize = 400; // stay under 500/commit
  for (let i = 0; i < entries.length; i += batchSize) {
    const slice = entries.slice(i, i + batchSize);
    const batch = db.batch();
    for (const [id, data] of slice) {
      const docRef = db.collection('tasks').doc(id);
      batch.set(docRef, data, { merge: true });
    }
    await batch.commit();
    console.log(`Committed ${slice.length} updates (total ${Math.min(i + slice.length, entries.length)}/${entries.length})`);
  }
  console.log('Done.');
}

run().catch((err) => {
  console.error('Failed to update tasks:', err);
  process.exit(1);
});
