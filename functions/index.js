const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {initializeApp} = require("firebase-admin/app");
const logger = require("firebase-functions/logger");

initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

exports.sendIncomingCallNotification = onDocumentCreated(
    "calls/{callId}",
    async (event) => {
      const call = event.data?.data();

      if (!call) {
        logger.warn("Call document has no data.");
        return;
      }

      // Only notify for newly created ringing calls.
      if (call.status !== "ringing") {
        logger.info("Ignoring non-ringing call.");
        return;
      }

      const callId = event.params.callId;
      const callerId = call.callerId;
      const calleeId = call.calleeId;

      if (!callerId || !calleeId) {
        logger.error("Call is missing callerId or calleeId.", {
          callId,
        });
        return;
      }

      const db = getFirestore();

      // Get caller profile so the callee sees the caller's name/photo.
      const callerSnap = await db
          .collection("users")
          .doc(callerId)
          .get();

      const caller = callerSnap.exists ? callerSnap.data() : {};

      const callerName =
          caller?.fullName ||
          caller?.displayName ||
          caller?.name ||
          "Incoming call";

      const callerPhotoUrl =
          caller?.photoUrl ||
          caller?.profilePhotoUrl ||
          "";

      // Get all FCM tokens registered for the callee.
      const calleeSnap = await db
          .collection("users")
          .doc(calleeId)
          .get();

      if (!calleeSnap.exists) {
        logger.warn("Callee profile not found.", {
          calleeId,
          callId,
        });
        return;
      }

      const callee = calleeSnap.data() || {};
      const tokens = Array.isArray(callee.fcmTokens) ?
        callee.fcmTokens.filter((token) => typeof token === "string") :
        [];

      if (tokens.length === 0) {
        logger.info("Callee has no FCM tokens.", {
          calleeId,
          callId,
        });
        return;
      }

      const message = {
        tokens,
        data: {
          type: "call",
          callId: String(callId),
          callerId: String(callerId),
          calleeId: String(calleeId),
          callerName: String(callerName),
          callerPhotoUrl: String(callerPhotoUrl),
          callType: call.type === "video" ? "video" : "audio",
        },
        android: {
          priority: "high",
        },
      };

      const response = await require("firebase-admin")
          .messaging()
          .sendEachForMulticast(message);

      logger.info("Incoming call notification sent.", {
        callId,
        calleeId,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      // Remove invalid/expired FCM tokens.
      const invalidTokens = [];

      response.responses.forEach((result, index) => {
        if (!result.success) {
          const code = result.error?.code;

          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(tokens[index]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await calleeSnap.ref.update({
          fcmTokens: require("firebase-admin")
              .firestore.FieldValue.arrayRemove(...invalidTokens),
        });

        logger.info("Removed invalid FCM tokens.", {
          count: invalidTokens.length,
          calleeId,
        });
      }
    },
);