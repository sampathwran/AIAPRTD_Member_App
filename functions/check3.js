const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_admin_dashboard/lib/service_account.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const snapshot = await db.collection("member").where("membershipNo", ">=", "AIAPRTD-25-").where("membershipNo", "<", "AIAPRTD-25-\uf8ff").get();
  console.log(`member query has ${snapshot.docs.length} docs`);
  
  if (snapshot.docs.length > 0) {
      console.log(snapshot.docs[0].data().membershipNo);
  }
}
run().then(() => console.log("Done")).catch(console.error);
