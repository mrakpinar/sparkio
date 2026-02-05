const functions = require("firebase-functions");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const path = require("path");

admin.initializeApp();

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
    const message = {
      topic: "all_users",
      notification: {
        title: "Tiny steps, big momentum",
        body: "Pick a quick task and feel the progress.",
      },
      data: {
        type: "daily_reminder",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sparkio_daily_v2",
        },
      },
    };

    try {
      await admin.messaging().send(message);
      return { ok: true };
    } catch (error) {
      console.error("sendDailyReminder failed", error);
      return { ok: false };
    }
  }
);
