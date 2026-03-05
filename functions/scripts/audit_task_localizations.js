/**
 * Audit active Firestore task titles against in-app localization sources.
 *
 * Usage:
 *   set FIREBASE_SERVICE_ACCOUNT=path/to/serviceAccount.json
 *   node scripts/audit_task_localizations.js --lang tr
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");

const langArgIndex = process.argv.indexOf("--lang");
const targetLang =
  langArgIndex >= 0 && process.argv[langArgIndex + 1]
    ? String(process.argv[langArgIndex + 1]).toLowerCase()
    : "tr";

function decodeDartEscapes(text) {
  return text.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) =>
    String.fromCharCode(parseInt(hex, 16))
  );
}

function normalize(text) {
  return String(text)
    .trim()
    .toLowerCase()
    .replace(/\u2019/g, "'")
    .replace(/\u2018/g, "'")
    .replace(/\s+/g, " ");
}

function extractMapBlock(content, mapName) {
  const start = content.indexOf(mapName);
  if (start < 0) return "";
  const braceStart = content.indexOf("{", start);
  if (braceStart < 0) return "";

  let depth = 0;
  let end = braceStart;
  for (; end < content.length; end++) {
    const ch = content[end];
    if (ch === "{") depth += 1;
    else if (ch === "}") {
      depth -= 1;
      if (depth === 0) break;
    }
  }
  return content.slice(braceStart + 1, end);
}

function extractKnownKeys(content, mapName) {
  const block = extractMapBlock(content, mapName);
  if (!block) return new Set();

  const keys = new Set();
  const keyRegex = /\n\s*'((?:\\'|[^'])+)'\s*:\s*\{/g;
  let match;
  while ((match = keyRegex.exec(block)) !== null) {
    const raw = match[1].replace(/\\'/g, "'");
    keys.add(normalize(decodeDartEscapes(raw)));
  }
  return keys;
}

async function main() {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountPath) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT env var is required for Firestore access."
    );
  }

  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const db = getFirestore(admin.app(), "default");
  const snap = await db.collection("tasks").where("active", "==", true).get();

  const firestoreTitles = [];
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (typeof data.title === "string" && data.title.trim()) {
      firestoreTitles.push(data.title.trim());
    }
  }

  const localizerPath = path.join(__dirname, "..", "..", "lib", "services", "task_localizer.dart");
  const appStringsPath = path.join(__dirname, "..", "..", "lib", "app_strings.dart");
  const localizerContent = fs.readFileSync(localizerPath, "utf8");
  const appStringsContent = fs.readFileSync(appStringsPath, "utf8");

  const known = new Set([
    ...extractKnownKeys(localizerContent, "_titleMap"),
    ...extractKnownKeys(localizerContent, "_fallbackTitleTranslations"),
    ...extractKnownKeys(appStringsContent, "_textMap"),
  ]);

  const missing = firestoreTitles
    .filter((title) => !known.has(normalize(title)))
    .sort((a, b) => a.localeCompare(b));

  console.log(
    JSON.stringify(
      {
        language: targetLang,
        firestoreCount: firestoreTitles.length,
        missingCount: missing.length,
        missing,
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
