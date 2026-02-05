const path = require("path");
const fs = require("fs");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");

const serviceAccountPath = path.join(__dirname, "..", "firebaseAdmin.json");
if (!fs.existsSync(serviceAccountPath)) {
  console.error("firebaseAdmin.json not found at:", serviceAccountPath);
  process.exit(1);
}

const tasksPath = path.join(__dirname, "..", "..", "assets", "tasks.json");
if (!fs.existsSync(tasksPath)) {
  console.error("tasks.json not found at:", tasksPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

// Use explicit database ID to avoid "(default)" resolution issues.
const db = getFirestore(admin.app(), "default");
db.settings({ ignoreUndefinedProperties: true });

const raw = fs.readFileSync(tasksPath, "utf8");
const tasks = JSON.parse(raw);

if (!Array.isArray(tasks)) {
  console.error("tasks.json is not an array");
  process.exit(1);
}

const chunk = (arr, size) => {
  const res = [];
  for (let i = 0; i < arr.length; i += size) {
    res.push(arr.slice(i, i + size));
  }
  return res;
};

async function run() {
  const batches = chunk(tasks, 500);
  let total = 0;
  for (const group of batches) {
    const batch = db.batch();
    for (const task of group) {
      if (!task || !task.id) {
        continue;
      }
      const docRef = db.collection("tasks").doc(String(task.id));
      batch.set(
        docRef,
        {
          ...task,
          active: task.active ?? true,
        },
        { merge: true }
      );
      total += 1;
    }
    await batch.commit();
  }
  console.log(`Uploaded ${total} tasks to Firestore.`);
}

run().catch((err) => {
  console.error("Upload failed:", err);
  process.exit(1);
});
