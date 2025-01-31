const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.cleanUpExpiredEvents = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const db = admin.firestore();
  const now = new Date();

  try {
    const expiredEventsSnapshot = await db.collection('activeEvents')
      .where('endDate', '<=', now)
      .get();

    const batch = db.batch();
    expiredEventsSnapshot.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${expiredEventsSnapshot.size} expired events.`);
  } catch (error) {
    console.error("Error cleaning expired events:", error);
  }
});
