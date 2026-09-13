const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_admin_dashboard/lib/service_account.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const webMembers = await db.collection("web_sync_member").get();
  const members = await db.collection("member").get();
  
  let webIds = new Set(webMembers.docs.map(d => d.id));
  let memIds = new Set(members.docs.map(d => d.id));
  
  let missingInMember = [...webIds].filter(id => !memIds.has(id));
  console.log(`There are ${missingInMember.length} documents in web_sync_member that are NOT in member`);
  if (missingInMember.length > 0) {
      console.log("Examples:", missingInMember.slice(0, 5));
  }
}
run().then(() => console.log("Done")).catch(console.error);
