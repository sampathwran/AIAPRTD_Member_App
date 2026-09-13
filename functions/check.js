const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_admin_dashboard/lib/service_account.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const snapshot = await db.collection("web_sync_member").get();
  console.log(`web_sync_member has ${snapshot.docs.length} docs`);
  let maxNum = 0;
  snapshot.docs.forEach(doc => {
      let id = doc.id;
      let parts = id.split('-');
      if (parts.length >= 3) {
          let num = parseInt(parts[2]);
          if (num > maxNum) maxNum = num;
      }
  });
  console.log(`Max membership number in web_sync_member is: ${maxNum}`);
}
run().then(() => console.log("Done")).catch(console.error);
