const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials
// Since we are running on the local machine with Firebase CLI authenticated, 
// we might need to specify the project id or use the emulator/live db.
admin.initializeApp({
  projectId: "aiaprtd-8822f" // Assuming this is the project ID
});

const db = admin.firestore();

async function fixBalances() {
    console.log("Starting balance recalculation for members with 0 transactions...");
    const membersSnap = await db.collection('member').get();
    let fixedCount = 0;
    
    for (const doc of membersSnap.docs) {
        const memberId = doc.id;
        const data = doc.data();
        
        const currentAppUsage = data.appUsageChargeBalance || 0;
        const currentSavings = data.savingsBalance || 0;

        // Skip if both balances are already 0 or less
        if (currentAppUsage <= 0 && currentSavings <= 0) {
            continue;
        }

        // Query transactions
        const txSnap = await db.collectionGroup('transactions').where('driverId', '==', memberId).get();
        
        if (txSnap.empty) {
            console.log(`Fixing member ${memberId} (AppUsage: ${currentAppUsage}, Savings: ${currentSavings}) -> Resetting to 0`);
            await doc.ref.update({
                appUsageChargeBalance: 0,
                savingsBalance: 0
            });
            fixedCount++;
        }
    }
    console.log(`Finished. Fixed ${fixedCount} members.`);
}

fixBalances().catch(console.error);
