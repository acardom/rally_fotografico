/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteUserByUid = functions.https.onCall(async (data, context) => {
  const uid = data.uid;
  if (!uid) throw new functions.https.HttpsError('invalid-argument', 'No uid provided');
  try {
    await admin.auth().deleteUser(uid);
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('unknown', error.message, error);
  }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
