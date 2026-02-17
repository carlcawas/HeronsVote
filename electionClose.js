const admin = require("firebase-admin");

const serviceAccount = require("./heronsvote-firebase-adminsdk-fbsvc-df5ce477bc.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const INTERVAL = 1 * 1000; // Every second

async function updateOngoingStatus() {
  const now = admin.firestore.Timestamp.now();
  const collectionsToCheck = ["elections", "proposals"];

  console.log("Checking documents at", new Date().toLocaleString());

  for (const colName of collectionsToCheck) {
    const snapshot = await db.collection(colName).get();

    if (snapshot.empty) {
      console.log(`No documents in ${colName}.`);
      continue;
    }

    const batch = db.batch();
    let changesMade = false;

    snapshot.forEach(doc => {
      const data = doc.data();
      const start = data.start;
      const end = data.end;
      let ongoing = data.ongoing;

      if (!start || !end) return;

      const shouldBeOngoing = start.toMillis() <= now.toMillis() && now.toMillis() <= end.toMillis();

      if (ongoing !== shouldBeOngoing) {
        batch.update(doc.ref, { ongoing: shouldBeOngoing });
        console.log(`${shouldBeOngoing ? "Opening" : "Closing"} ${colName} document:`, doc.id);
        changesMade = true;
      }
    });

    if (changesMade) {
      await batch.commit();
    } else {
      console.log(`No status changes needed in ${colName}.`);
    }
  }
}

updateOngoingStatus();
setInterval(updateOngoingStatus, INTERVAL);