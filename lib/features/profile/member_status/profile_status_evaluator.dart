import 'package:aiaprtd_member/features/profile/member_status/membership_fee_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/personal_kyc_checker.dart';
import 'package:aiaprtd_member/features/profile/member_status/vehicle_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/profile_image_status_check.dart';
import 'package:aiaprtd_member/features/profile/member_status/admin_block_status_check.dart';

Map<String, dynamic> calculateMemberStatus(Map<String, dynamic> activeData) {
  List<String> reasons = [];
  bool isActive = true;

  print("🟢 [STATUS EVALUATOR] Calculating Member Status...");

  // 1. Membership Fee Check (අනිවාර්යයෙන්ම මුලින්ම චෙක් වෙන්න ඕනේ)
  final Map<String, dynamic> feeCheck = checkMembershipFeeStatus(activeData);
  if (feeCheck['isFeePaidValid'] == false) {
    isActive = false;
    reasons.add(feeCheck['reason'] ?? 'Pending Membership Fee 💰');
  }

  // 2. KYC Check
  final Map<String, dynamic> kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
  if (kycCheck['isVerified'] == false) {
    isActive = false;
    if (kycCheck['reason'] != null && kycCheck['reason'] != "Verification pending ⏳") {
      reasons.add(kycCheck['reason']);
    } else {
      reasons.add("Personal profile or face verification pending.");
    }
  }

  // 3. Profile Image Check
  final Map<String, dynamic> imageCheck = checkProfileImageStatus(activeData);
  if (imageCheck['isActive'] == false) {
    isActive = false;
    reasons.add(imageCheck['reason']);
  }

  // 4. Vehicle Check
  final Map<String, dynamic> vehicleCheck = checkMemberSystemStatus(activeData);
  if (vehicleCheck['isActive'] == false) {
    isActive = false;
    reasons.add(vehicleCheck['reason'] ?? 'Vehicle verification pending.');
  }

  // 5. Admin Block Check
  final Map<String, dynamic> blockCheck = checkAdminBlockStatus(activeData);
  if (blockCheck['isActive'] == false) {
    isActive = false;
    reasons.add(blockCheck['reason']);
  }

  // ප්‍රතිඵලය ආපසු යැවීම
  return {
    'isActive': isActive,
    'reasons': reasons,
  };
}