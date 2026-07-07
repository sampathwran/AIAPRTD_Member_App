// 💡 Firebase Functions v2 Firestore trigger එක ලබාගැනීම
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require('firebase-admin');
const { RekognitionClient, CompareFacesCommand } = require("@aws-sdk/client-rekognition");
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// 🔐 AWS Credentials Setup
// (මතක ඇතුව ඔයාගේ රහස්‍ය AWS Access Key සහ Secret Key එක විතරක් මෙතනට දාන්න)
const rekognition = new RekognitionClient({
    region: "us-east-1",
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "YOUR_ACCESS_KEY_HERE",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "YOUR_SECRET_KEY_HERE"
    }
});

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

            const awsResponse = await rekognition.send(command);

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
                'verifiedAt': admin.firestore.FieldValue.serverTimestamp()
            });

            const memberRef = db.collection('member').doc(membershipNo);
            batch.update(memberRef, {
                'status': finalStatus,
                'faceKycStatus': finalStatus,
                'updatedAt': admin.firestore.FieldValue.serverTimestamp()
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