const admin = require("firebase-admin");
const serviceAccount = require("./aiaprtd-member-firebase-adminsdk-jntls-cd2ef97669.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const snapshot = await db.collection("web_sync_member").get();
  console.log(`Found ${snapshot.docs.length} members to sync`);
  
  let batch = db.batch();
  let count = 0;
  
  for (const doc of snapshot.docs) {
    batch.set(db.collection("member").doc(doc.id), doc.data(), { merge: true });
    count++;
    
    if (count % 400 === 0) {
      await batch.commit();
      console.log(`Committed ${count}`);
      batch = db.batch();
    }
  }
  
  if (count % 400 !== 0) {
    await batch.commit();
    console.log(`Committed remaining, total ${count}`);
  }
}
run().then(() => console.log("Done")).catch(console.error);
