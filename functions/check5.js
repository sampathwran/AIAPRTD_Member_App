const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_admin_dashboard/lib/service_account.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  let doc = await db.collection("member").doc("AIAPRTD-25-0151").get();
  if (doc.exists) {
      console.log("member document:", doc.data());
  } else {
      console.log("member document DOES NOT EXIST");
  }

  let doc2 = await db.collection("web_sync_member").doc("AIAPRTD-25-0151").get();
  if (doc2.exists) {
      console.log("web_sync_member document:", doc2.data());
  } else {
      console.log("web_sync_member document DOES NOT EXIST");
  }
}
run().then(() => console.log("Done")).catch(console.error);
