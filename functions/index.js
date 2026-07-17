// 💡 Firebase Functions v2 Firestore trigger එක ලබාගැනීම
const { onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { RekognitionClient, CompareFacesCommand } = require("@aws-sdk/client-rekognition");
const axios = require('axios');

initializeApp();
const db = getFirestore();

// 🔐 AWS Credentials Setup
// (මතක ඇතුව ඔයාගේ රහස්‍ය AWS Access Key සහ Secret Key එක විතරක් මෙතනට දාන්න)
let rekognition;
function getRekognitionClient() {
    if (!rekognition) {
        rekognition = new RekognitionClient({
            region: "us-east-1",
            credentials: {
                accessKeyId: process.env.AWS_ACCESS_KEY_ID || "YOUR_ACCESS_KEY_HERE",
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "YOUR_SECRET_KEY_HERE"
            }
        });
    }
    return rekognition;
}

// 🚀 v2 Firestore Trigger එක ක්‍රියාත්මක වන ආකාරය
exports.onFaceVerificationUpdate = onDocumentUpdated('verify_kyc/{membershipNo}', async (event) => {
    // 💡 v2 එකේ ඩේටා ගන්නේ 'event.data' හරහායි
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const membershipNo = event.params.membershipNo;

    // 🎯 1. faceVerificationUrl එක කලින් හිස්ව තිබී දැන් අලුතෙන් update වුණාදැයි බැලීම
    if (!beforeData.faceVerificationUrl && afterData.faceVerificationUrl) {
        console.log(`🤖 AI Face Verification Started for Membership No: ${membershipNo}`);

        try {
            // 🎯 2. 'profile_image_requests' collection එකෙන් යූසර්ගේ Approved Profile Image එක ලබාගැනීම
            const profileRequestDoc = await db.collection('profile_image_requests').doc(membershipNo).get();
            if (!profileRequestDoc.exists) {
                console.error(`❌ Profile Image Request Document not found for: ${membershipNo}`);
                return;
            }

            const profileData = profileRequestDoc.data();
            const profileImageUrl = profileData.newImageUrl;

            if (profileData.status !== 'approved') {
                console.warn(`⚠️ Warning: Profile image status is '${profileData.status}', not 'approved'. Proceeding anyway...`);
            }

            if (!profileImageUrl) {
                console.error(`❌ Reference Image URL (newImageUrl) not found for: ${membershipNo}`);
                return;
            }

            console.log(`📸 Comparing Reference Image (${profileImageUrl}) with Live Selfie (${afterData.faceVerificationUrl})`);

            // 🎯 3. ෆොටෝ දෙක Fetch කරලා Buffer එකක් විදිහට AWS එකට යැවීම
            const res1 = await axios.get(profileImageUrl, { responseType: 'arraybuffer' });
            const res2 = await axios.get(afterData.faceVerificationUrl, { responseType: 'arraybuffer' });

            const command = new CompareFacesCommand({
                SourceImage: { Bytes: Buffer.from(res1.data) },
                TargetImage: { Bytes: Buffer.from(res2.data) },
                SimilarityThreshold: 80
            });

            const awsClient = getRekognitionClient();
            const awsResponse = await awsClient.send(command);

            // 🎯 4. ප්‍රතිඵලය අනුව Status එක තීරණය කිරීම
            let finalStatus = 'rejected';
            let matchPercentage = 0;

            if (awsResponse.FaceMatches && awsResponse.FaceMatches.length > 0) {
                matchPercentage = awsResponse.FaceMatches[0].Similarity;
                console.log(`📊 Similarity Score: ${matchPercentage}%`);

                if (matchPercentage >= 85.0) {
                    finalStatus = 'approved';
                }
            } else {
                console.log("❌ No face match found between images.");
            }

            // 🎯 5. Firestore Collections දෙකම එකවර Auto Update කිරීම
            const batch = db.batch();

            const verifyRef = db.collection('verify_kyc').doc(membershipNo);
            batch.update(verifyRef, {
                'status': finalStatus,
                'faceMatchScore': parseFloat(matchPercentage.toFixed(2)),
                'verifiedAt': FieldValue.serverTimestamp()
            });

            const memberRef = db.collection('member').doc(membershipNo);
            batch.update(memberRef, {
                'status': finalStatus,
                'faceKycStatus': finalStatus,
                'updatedAt': FieldValue.serverTimestamp()
            });

            await batch.commit();
            console.log(`✅ Auto Verification Completed. Status set to: ${finalStatus}`);

        } catch (error) {
            console.error("❌ Cloud Function Error:", error);
            await db.collection('verify_kyc').doc(membershipNo).update({
                'status': 'failed_error',
                'errorMessage': error.message
            });
        }
    }
});

// 🚀 Revert App Usage and Savings balances when a transaction is deleted
exports.onFinanceTxDeleted = onDocumentDeleted('finance_transactions/{transactionId}', async (event) => {
    const deletedData = event.data.data();
    if (!deletedData) return;

    const type = deletedData.type;
    const driverId = deletedData.driverId;
    const passengerId = deletedData.passengerId;
    const batch = db.batch();

    console.log(`🗑️ Reverting deleted transaction ${event.params.transactionId} of type ${type}`);

    try {
        if (type === 'app_booking_commission_split' || type === 'road_pickup_commission') {
            const driverCommission = deletedData.driverCommission || 0;
            const passengerSavings = deletedData.passengerSavings || 0;

            // Revert App Usage Charge for Driver
            if (driverId && driverCommission > 0) {
                const driverRef = db.collection('members').doc(driverId);
                batch.update(driverRef, {
                    'appUsageChargeBalance': FieldValue.increment(-driverCommission)
                });
                console.log(`📉 Reverting LKR ${driverCommission} from driver ${driverId} App Usage Charge`);
            }

            // Revert Savings for Passenger (only in App Booking)
            if (passengerId && passengerSavings > 0 && type === 'app_booking_commission_split') {
                const passengerRef = db.collection('members').doc(passengerId);
                batch.update(passengerRef, {
                    'savingsBalance': FieldValue.increment(-passengerSavings)
                });
                console.log(`📉 Reverting LKR ${passengerSavings} from passenger ${passengerId} Savings`);
            }
        } else if (type === 'auto_settlement') {
            const amount = deletedData.amount || 0;
            const memberId = driverId || passengerId;
            
            // Revert the auto-settlement by adding the amount back to BOTH balances
            if (memberId && amount > 0) {
                const memberRef = db.collection('members').doc(memberId);
                batch.update(memberRef, {
                    'appUsageChargeBalance': FieldValue.increment(amount),
                    'savingsBalance': FieldValue.increment(amount)
                });
                console.log(`📈 Reverting auto-settlement, adding LKR ${amount} back to member ${memberId}`);
            }
        }

        await batch.commit();
        console.log(`✅ Successfully reverted balances for deleted transaction ${event.params.transactionId}`);
    } catch (error) {
        console.error("❌ Error reverting deleted transaction:", error);
    }
});

// 🚀 Cascade delete finance transactions when a Booking Hire is deleted
exports.onBookingHireDeleted = onDocumentDeleted('booking_hires/{date}/{memberId}/{tripId}', async (event) => {
    await deleteAssociatedFinanceTransactions(event.params.tripId);
});

// 🚀 Cascade delete finance transactions when a Road Pickup Hire is deleted
exports.onRoadPickupHireDeleted = onDocumentDeleted('roadpickups_hires/{date}/{memberId}/{tripId}', async (event) => {
    await deleteAssociatedFinanceTransactions(event.params.tripId);
});

// Helper function to delete finance transactions by tripId
async function deleteAssociatedFinanceTransactions(tripId) {
    if (!tripId) return;
    try {
        console.log(`🔍 Searching for finance_transactions with tripId: ${tripId}`);
        const snapshot = await db.collection('finance_transactions').where('tripId', '==', tripId).get();
        
        if (snapshot.empty) {
            console.log(`ℹ️ No finance_transactions found for tripId: ${tripId}`);
            return;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
            console.log(`🗑️ Queued deletion of finance_transaction: ${doc.id}`);
        });

        await batch.commit();
        console.log(`✅ Deleted ${snapshot.size} finance_transaction(s) for tripId ${tripId}`);
    } catch (error) {
        console.error(`❌ Error deleting finance transactions for tripId ${tripId}:`, error);
    }
}