/**
 * Normalize Firestore tasks copy + duration and optionally upsert a local catalog.
 *
 * Usage:
 *   node scripts/normalize_tasks_in_firestore.js            // dry run
 *   node scripts/normalize_tasks_in_firestore.js --apply    // write changes
 *
 * Service account resolution:
 *   1) FIREBASE_SERVICE_ACCOUNT env var
 *   2) functions/firebaseAdmin.json
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");

const args = new Set(process.argv.slice(2));
const APPLY = args.has("--apply");

const explicitTitleMap = {
  seed: "Write one tiny intention for today",
  reset: "Take 5 slow breaths and reset",
  focus: "Write one priority and start for 2 minutes",
  reflect: "Write one line about your day",
  hydrate: "Drink one full glass of water",
  pause: "Pause for 1 minute and breathe",
  move: "Stand up and move for 2 minutes",
  task: "Start one tiny action now",
  spark: "Take one small action now",
};

const localCatalog = [
  {
    id: "local_mind_1",
    title: "Take 3 slow breaths",
    category: "mind",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_mind_2",
    title: "Write one clear priority for today",
    category: "mind",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_mind_3",
    title: "Clear one distraction from your desk",
    category: "mind",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_mind_4",
    title: "Close extra tabs and focus for 3 minutes",
    category: "mind",
    difficulty: "medium",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_mind_5",
    title: "Name one thing you can control today",
    category: "mind",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_mind_6",
    title: "Write one win from your day",
    category: "mind",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_body_1",
    title: "Stand up and stretch your neck and shoulders",
    category: "body",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_body_2",
    title: "Do 10 squats at your own pace",
    category: "body",
    difficulty: "medium",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_body_3",
    title: "Walk for 4 minutes",
    category: "body",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_body_4",
    title: "Roll your shoulders for 60 seconds",
    category: "body",
    difficulty: "easy",
    durationMinutes: 1,
    durationSeconds: 60,
    active: true,
  },
  {
    id: "local_body_5",
    title: "Do 8 wall push-ups",
    category: "body",
    difficulty: "medium",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_body_6",
    title: "Stretch your calves for 2 minutes",
    category: "body",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_growth_1",
    title: "Read one page of something useful",
    category: "growth",
    difficulty: "easy",
    durationMinutes: 5,
    active: true,
  },
  {
    id: "local_growth_2",
    title: "Learn one new word and use it in a sentence",
    category: "growth",
    difficulty: "medium",
    durationMinutes: 5,
    active: true,
  },
  {
    id: "local_growth_3",
    title: "Plan tomorrow in three bullet points",
    category: "growth",
    difficulty: "easy",
    durationMinutes: 5,
    active: true,
  },
  {
    id: "local_growth_4",
    title: "Organize one small area around you",
    category: "growth",
    difficulty: "easy",
    durationMinutes: 5,
    active: true,
  },
  {
    id: "local_growth_5",
    title: "Write one idea to improve your routine",
    category: "growth",
    difficulty: "medium",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_growth_6",
    title: "Start a task you avoid for just 2 minutes",
    category: "growth",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_calm_1",
    title: "Breathe in for 4 and out for 6 for 2 minutes",
    category: "calm",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_calm_2",
    title: "Sit quietly and notice sounds for 2 minutes",
    category: "calm",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_calm_3",
    title: "Relax your jaw and shoulders",
    category: "calm",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_calm_4",
    title: "Do a short body scan for 3 minutes",
    category: "calm",
    difficulty: "medium",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_calm_5",
    title: "Step away from your screen for 2 minutes",
    category: "calm",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_calm_6",
    title: "Put your phone down and breathe for 60 seconds",
    category: "calm",
    difficulty: "easy",
    durationMinutes: 1,
    durationSeconds: 60,
    active: true,
  },
  {
    id: "local_health_1",
    title: "Drink one full glass of water",
    category: "health",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_health_2",
    title: "Refill your water bottle now",
    category: "health",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_health_3",
    title: "Eat one healthy snack",
    category: "health",
    difficulty: "easy",
    durationMinutes: 4,
    active: true,
  },
  {
    id: "local_health_4",
    title: "Step outside for fresh air for 3 minutes",
    category: "health",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
  {
    id: "local_health_5",
    title: "Reset your posture for 2 minutes",
    category: "health",
    difficulty: "easy",
    durationMinutes: 2,
    active: true,
  },
  {
    id: "local_health_6",
    title: "Do a 20-20-20 eye break",
    category: "health",
    difficulty: "easy",
    durationMinutes: 3,
    active: true,
  },
];

const durationBands = {
  easy: { def: 5, min: 3, max: 8 },
  medium: { def: 8, min: 5, max: 12 },
  hard: { def: 12, min: 8, max: 18 },
};

function serviceAccountPath() {
  const fromEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (fromEnv && fs.existsSync(fromEnv)) return fromEnv;
  const local = path.join(__dirname, "..", "firebaseAdmin.json");
  if (fs.existsSync(local)) return local;
  return null;
}

function normalizeCategory(raw) {
  const c = String(raw ?? "").toLowerCase().trim();
  if (["mind", "body", "growth", "calm", "health"].includes(c)) return c;
  return "mind";
}

function normalizeDifficulty(raw) {
  const d = String(raw ?? "").toLowerCase().trim();
  if (d === "easy" || d === "medium" || d === "hard") return d;
  return "easy";
}

function fallbackTitleForCategory(category) {
  switch (category) {
    case "body":
      return "Move your body for 2 minutes";
    case "growth":
      return "Write one small improvement idea";
    case "calm":
      return "Take 5 slow breaths";
    case "health":
      return "Drink one glass of water";
    case "mind":
    default:
      return "Write one clear priority";
  }
}

function normalizeTitle(rawTitle, category) {
  const value = String(rawTitle ?? "").replace(/\s+/g, " ").trim();
  if (!value) return fallbackTitleForCategory(category);
  const key = value.toLowerCase().replace(/[^a-z0-9]+/g, "");
  return explicitTitleMap[key] || value;
}

function normalizeDuration(task, difficulty) {
  const secRaw = Number(task.durationSeconds);
  const hasSeconds = Number.isFinite(secRaw) && secRaw > 0;
  const safeSeconds = hasSeconds
    ? Math.max(1, Math.min(360000, Math.floor(secRaw)))
    : undefined;

  if (safeSeconds !== undefined) {
    return {
      durationMinutes: Math.max(1, Math.min(120, Math.ceil(safeSeconds / 60))),
      durationSeconds: safeSeconds,
    };
  }

  const band = durationBands[difficulty] || durationBands.easy;
  const min = band.min;
  const max = band.max;
  const def = band.def;
  const minsRaw = Number(task.durationMinutes);
  const mins = Number.isFinite(minsRaw) ? Math.floor(minsRaw) : 0;
  const normalized = mins <= 0 ? def : Math.max(min, Math.min(max, mins));
  return { durationMinutes: normalized };
}

function computePatch(existing, normalized) {
  const patch = {};
  const fields = [
    "title",
    "category",
    "difficulty",
    "durationMinutes",
    "durationSeconds",
    "active",
  ];
  for (const field of fields) {
    if (normalized[field] === undefined) continue;
    if (existing[field] !== normalized[field]) {
      patch[field] = normalized[field];
    }
  }
  return patch;
}

function normalizeTask(existing, fallbackId) {
  const category = normalizeCategory(existing.category);
  const difficulty = normalizeDifficulty(existing.difficulty);
  const title = normalizeTitle(existing.title, category);
  const duration = normalizeDuration(existing, difficulty);

  return {
    id: String(existing.id || fallbackId || ""),
    title,
    category,
    difficulty,
    active: existing.active !== false,
    ...duration,
  };
}

async function commitInBatches(updates, db) {
  const size = 400;
  let done = 0;
  for (let i = 0; i < updates.length; i += size) {
    const slice = updates.slice(i, i + size);
    const batch = db.batch();
    for (const item of slice) {
      batch.set(item.ref, item.data, { merge: true });
    }
    await batch.commit();
    done += slice.length;
    console.log(`Committed ${done}/${updates.length}`);
  }
}

async function run() {
  const keyPath = serviceAccountPath();
  if (!keyPath) {
    console.error(
      "Service account not found. Set FIREBASE_SERVICE_ACCOUNT or place functions/firebaseAdmin.json"
    );
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
  });
  const db = getFirestore(admin.app(), "default");
  db.settings({ ignoreUndefinedProperties: true });

  const snap = await db.collection("tasks").get();
  const byId = new Map();
  snap.docs.forEach((doc) => byId.set(doc.id, doc));

  const updates = [];
  let normalizedExisting = 0;
  for (const doc of snap.docs) {
    const existing = doc.data() || {};
    const normalized = normalizeTask(existing, doc.id);
    const patch = computePatch(existing, normalized);
    if (Object.keys(patch).length > 0) {
      updates.push({ ref: doc.ref, data: patch });
      normalizedExisting += 1;
    }
  }

  let catalogUpserts = 0;
  for (const item of localCatalog) {
    const ref = db.collection("tasks").doc(item.id);
    const existingDoc = byId.get(item.id);
    const existing = existingDoc ? existingDoc.data() || {} : {};
    const normalized = normalizeTask(item, item.id);
    const patch = existingDoc
      ? computePatch(existing, normalized)
      : normalized;
    if (Object.keys(patch).length > 0) {
      updates.push({ ref, data: patch });
      catalogUpserts += 1;
    }
  }

  console.log(
    JSON.stringify(
      {
        mode: APPLY ? "apply" : "dry-run",
        scanned: snap.size,
        normalizedExisting,
        catalogUpserts,
        totalWrites: updates.length,
      },
      null,
      2
    )
  );

  if (!APPLY) {
    console.log("Dry run only. Re-run with --apply to write changes.");
    return;
  }

  if (updates.length === 0) {
    console.log("No changes to apply.");
    return;
  }

  await commitInBatches(updates, db);
  console.log("Done.");
}

run().catch((err) => {
  console.error("normalize_tasks_in_firestore failed:", err);
  process.exit(1);
});

