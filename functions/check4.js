const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_admin_dashboard/lib/service_account.json");
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function run() {
  const snapshot = await db.collection("member").where("membershipNo", ">=", "AIAPRTD-25-").where("membershipNo", "<", "AIAPRTD-25-\uf8ff").get();
  
  let nums = [];
  snapshot.docs.forEach(d => {
      let parts = d.data().membershipNo.split('-');
      if (parts.length >= 3) {
          nums.push(parseInt(parts[2]));
      }
  });
  console.log(`Max is ${Math.max(...nums)}`);
  console.log(nums.sort((a,b)=>a-b).join(', '));
}
run().then(() => console.log("Done")).catch(console.error);
