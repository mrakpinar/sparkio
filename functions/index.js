const functions = require("firebase-functions/v1");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { google } = require("googleapis");
const crypto = require("crypto");
const path = require("path");

admin.initializeApp();
const db = getFirestore("default");

const serviceAccountPath = path.join(__dirname, "serviceAccount.json");

const auth = new google.auth.GoogleAuth({
  keyFile: serviceAccountPath,
  scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

const androidpublisher = google.androidpublisher("v3");

exports.verifyPurchase = functions.https.onCall(async (data) => {
  const packageName = data.packageName;
  const productId = data.productId;
  const purchaseToken = data.purchaseToken;

  if (!packageName || !productId || !purchaseToken) {
    return { valid: false, reason: "missing_fields" };
  }

  try {
    const client = await auth.getClient();
    const response = await androidpublisher.purchases.subscriptions.get({
      auth: client,
      packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    const expiry = Number(response.data.expiryTimeMillis || 0);
    const valid = expiry > Date.now();

    return {
      valid,
      expiryTimeMillis: response.data.expiryTimeMillis,
    };
  } catch (error) {
    return { valid: false, reason: "api_error" };
  }
});

exports.sendDailyReminder = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Europe/Istanbul",
    region: "us-central1",
  },
  async () => {
    const languages = {
      en: { title: "Tiny steps, big momentum", body: "Pick a quick task and feel the progress." },
      tr: { title: "Küçük adımlar, büyük ivme", body: "Hızlı bir görev seç ve ilerlemeyi hisset." },
      es: { title: "Pequeños pasos, gran impulso", body: "Elige una tarea rápida y siente el progreso." },
      de: { title: "Kleine Schritte, großes Momentum", body: "Wähle eine schnelle Aufgabe und spüre den Fortschritt." }
    };

    const messages = [];

    // Localized messages for updated clients
    for (const [lang, notification] of Object.entries(languages)) {
      messages.push({
        topic: `sparkio_lang_${lang}`,
        notification,
        data: { type: "daily_reminder" },
        android: {
          priority: "high",
          notification: { channelId: "sparkio_daily_v2" },
        },
      });
    }

    // Fallback message for older clients (uses English by default)
    messages.push({
      condition: "'all_users' in topics && !('sparkio_v2' in topics)",
      notification: languages.en,
      data: { type: "daily_reminder" },
      android: {
        priority: "high",
        notification: { channelId: "sparkio_daily_v2" },
      },
    });

    try {
      const results = await Promise.all(
        messages.map((msg) => admin.messaging().send(msg).catch((e) => {
          console.error(`Failed to send message: ${msg.topic || msg.condition}`, e);
          return null;
        }))
      );
      
      return { ok: true, results };
    } catch (error) {
      console.error("sendDailyReminder failed", error);
      return { ok: false };
    }
  }
);

const REFERRAL_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const REFERRAL_CODE_LENGTH = 8;
const REFERRAL_MAX_GENERATION_ATTEMPTS = 8;
const REFERRAL_USERS_COLLECTION = "referral_users";
const REFERRAL_CODES_COLLECTION = "referral_codes";
const REFERRAL_CLAIMS_COLLECTION = "referral_claims";

function _normalizeInstallId(raw) {
  if (typeof raw !== "string") return "";
  return raw.trim().toLowerCase();
}

function _normalizeReferralCode(raw) {
  if (typeof raw !== "string") return "";
  return raw.trim().toUpperCase().replace(/[^A-Z0-9]/g, "");
}

function _safeInt(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.floor(value));
  }
  return 0;
}

function _generateReferralCode() {
  const bytes = crypto.randomBytes(REFERRAL_CODE_LENGTH);
  let code = "";
  for (let i = 0; i < REFERRAL_CODE_LENGTH; i++) {
    code += REFERRAL_CODE_ALPHABET[bytes[i] % REFERRAL_CODE_ALPHABET.length];
  }
  return code;
}

function _referralResponse(data) {
  return {
    code: typeof data.code === "string" ? data.code : "",
    invitedCount: _safeInt(data.invitedCount),
    redeemedCode:
      typeof data.redeemedCode === "string" ? data.redeemedCode : null,
    creditsGranted: _safeInt(data.rewardCreditsGranted),
    creditsClaimed: _safeInt(data.rewardCreditsClaimed),
  };
}

exports.getOrCreateReferralCode = functions.https.onCall(async (data) => {
  const installId = _normalizeInstallId(data?.installId);
  if (!installId || installId.length < 8) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "install_id_required",
    );
  }

  const userRef = db.collection(REFERRAL_USERS_COLLECTION).doc(installId);
  const codesCol = db.collection(REFERRAL_CODES_COLLECTION);

  const payload = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const existingCode = _normalizeReferralCode(userData.code);

    if (existingCode) {
      return _referralResponse({ ...userData, code: existingCode });
    }

    let generatedCode = "";
    for (let i = 0; i < REFERRAL_MAX_GENERATION_ATTEMPTS; i++) {
      const candidate = _generateReferralCode();
      const candidateRef = codesCol.doc(candidate);
      const candidateSnap = await tx.get(candidateRef);
      if (!candidateSnap.exists) {
        generatedCode = candidate;
        tx.set(
          candidateRef,
          {
            ownerInstallId: installId,
            code: generatedCode,
            uses: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        break;
      }
    }

    if (!generatedCode) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "referral_code_generation_failed",
      );
    }

    tx.set(
      userRef,
      {
        installId,
        code: generatedCode,
        invitedCount: _safeInt(userData.invitedCount),
        rewardCreditsGranted: _safeInt(userData.rewardCreditsGranted),
        rewardCreditsClaimed: _safeInt(userData.rewardCreditsClaimed),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt:
          userData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return _referralResponse({ ...userData, code: generatedCode });
  });

  return { ok: true, ...payload };
});

exports.redeemReferralCode = functions.https.onCall(async (data) => {
  const installId = _normalizeInstallId(data?.installId);
  const code = _normalizeReferralCode(data?.code);

  if (!installId || installId.length < 8) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "install_id_required",
    );
  }
  if (!code || code.length < 4) {
    throw new functions.https.HttpsError("invalid-argument", "code_required");
  }

  const usersCol = db.collection(REFERRAL_USERS_COLLECTION);
  const codesCol = db.collection(REFERRAL_CODES_COLLECTION);
  const claimsCol = db.collection(REFERRAL_CLAIMS_COLLECTION);

  await db.runTransaction(async (tx) => {
    const inviteeRef = usersCol.doc(installId);
    const codeRef = codesCol.doc(code);
    const inviteeSnap = await tx.get(inviteeRef);
    const inviteeData = inviteeSnap.exists ? inviteeSnap.data() || {} : {};

    if (_normalizeReferralCode(inviteeData.redeemedCode)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "already_redeemed",
      );
    }

    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new functions.https.HttpsError("not-found", "invalid_code");
    }
    const codeData = codeSnap.data() || {};
    const inviterInstallId = _normalizeInstallId(codeData.ownerInstallId);
    if (!inviterInstallId) {
      throw new functions.https.HttpsError("not-found", "invalid_code");
    }
    if (inviterInstallId === installId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "self_referral",
      );
    }

    const inviterRef = usersCol.doc(inviterInstallId);
    const inviterSnap = await tx.get(inviterRef);
    const inviterData = inviterSnap.exists ? inviterSnap.data() || {} : {};

    const claimRef = claimsCol.doc(`${inviterInstallId}_${installId}`);
    const claimSnap = await tx.get(claimRef);
    if (claimSnap.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "already_redeemed",
      );
    }

    tx.set(
      claimRef,
      {
        inviterInstallId,
        inviteeInstallId: installId,
        code,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      inviteeRef,
      {
        installId,
        redeemedBy: inviterInstallId,
        redeemedCode: code,
        rewardCreditsGranted: _safeInt(inviteeData.rewardCreditsGranted) + 1,
        rewardCreditsClaimed: _safeInt(inviteeData.rewardCreditsClaimed),
        invitedCount: _safeInt(inviteeData.invitedCount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt:
          inviteeData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      inviterRef,
      {
        installId: inviterInstallId,
        invitedCount: _safeInt(inviterData.invitedCount) + 1,
        rewardCreditsGranted: _safeInt(inviterData.rewardCreditsGranted) + 1,
        rewardCreditsClaimed: _safeInt(inviterData.rewardCreditsClaimed),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt:
          inviterData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      codeRef,
      {
        uses: _safeInt(codeData.uses) + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return { ok: true };
});

exports.syncReferralRewards = functions.https.onCall(async (data) => {
  const installId = _normalizeInstallId(data?.installId);
  if (!installId || installId.length < 8) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "install_id_required",
    );
  }

  const usersCol = db.collection(REFERRAL_USERS_COLLECTION);
  const userRef = usersCol.doc(installId);

  const payload = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      return {
        code: "",
        invitedCount: 0,
        redeemedCode: null,
        creditsGranted: 0,
        creditsClaimed: 0,
        claimableCredits: 0,
      };
    }

    const data = userSnap.data() || {};
    const granted = _safeInt(data.rewardCreditsGranted);
    const claimed = _safeInt(data.rewardCreditsClaimed);
    const claimableCredits = Math.max(granted - claimed, 0);
    const nextClaimed = claimed + claimableCredits;

    if (claimableCredits > 0) {
      tx.set(
        userRef,
        {
          rewardCreditsClaimed: nextClaimed,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    return {
      ..._referralResponse({
        ...data,
        rewardCreditsClaimed: nextClaimed,
      }),
      claimableCredits,
    };
  });

  return { ok: true, ...payload };
});
