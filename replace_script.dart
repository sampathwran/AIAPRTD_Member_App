import 'dart:io';

void main() {
  // First time login screen
  var f1 = File('lib/features/auth/first_time_login_screen.dart');
  var code1 = f1.readAsStringSync();
  if (!code1.contains('app_errors.dart')) {
    code1 = "import '../../core/utils/app_errors.dart';\n" + code1;
  }
  
  code1 = code1.replaceAll(
    'void _showSnackBar(String message, Color backgroundColor) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message), backgroundColor: backgroundColor),\n    );\n  }',
    'void _showSnackBar(String message, [Color backgroundColor = Colors.redAccent]) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4, fontSize: 13)), backgroundColor: backgroundColor, duration: const Duration(seconds: 5)),\n    );\n  }'
  );
  code1 = code1.replaceAll(
    "String errorMsg = 'An error occurred. Please contact Admin.';",
    "String errorMsg = AppErrors.genericError;"
  );
  code1 = code1.replaceAll(
    "errorMsg = 'This account is already activated. Please log in normally.';",
    "errorMsg = AppErrors.accountAlreadyActivated;"
  );
  code1 = code1.replaceAll(
    "errorMsg = 'The password is too weak. Min 6 characters required.';",
    "errorMsg = AppErrors.weakPassword;"
  );
  code1 = code1.replaceAll(
    '_showSnackBar("An unexpected technical error occurred. Please contact Admin.", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("A technical error occurred while checking the record. Please contact Admin.", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code1 = code1.replaceAll(
    "_showSnackBar('Phone verification failed. Please try again later or contact Admin.', Colors.redAccent);",
    "_showSnackBar(AppErrors.genericError);"
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Invalid OTP code entered. Please check and try again.", Colors.redAccent);',
    '_showSnackBar(AppErrors.invalidOtp);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("OTP verification failed. Please try again later or contact Admin.", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Account exists but password incorrect. Please use the password you registered with.", Colors.orange);',
    '_showSnackBar(AppErrors.incorrectPassword, Colors.orange);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Verification session expired. Please go back and try again.", Colors.redAccent);',
    '_showSnackBar(AppErrors.sessionExpired);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Associated Mobile Number not found in record. Contact Admin (07XXXXXXXX).", Colors.redAccent);',
    '_showSnackBar(AppErrors.mobileNotFound);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Associated email not found in record. Contact Admin.", Colors.redAccent);',
    '_showSnackBar(AppErrors.memberNotFound);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("No pre-registered account found with this Membership No.", Colors.redAccent);',
    '_showSnackBar(AppErrors.memberNotFound);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Please enter your Membership No (e.g. AIAPRTD-26-XXXX), not your Email.", Colors.redAccent);',
    '_showSnackBar(AppErrors.memberNotFound);'
  );
  code1 = code1.replaceAll(
    '_showSnackBar("Please enter your Membership Number", Colors.redAccent);',
    '_showSnackBar(AppErrors.emptyFields);'
  );
  f1.writeAsStringSync(code1);

  // Login screen
  var f2 = File('lib/features/auth/login_screen.dart');
  var code2 = f2.readAsStringSync();
  if (!code2.contains('app_errors.dart')) {
    code2 = "import '../../core/utils/app_errors.dart';\n" + code2;
  }
  
  code2 = code2.replaceAll(
    'void _showSnackBar(String message) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message)),\n    );\n  }',
    'void _showSnackBar(String message, [Color backgroundColor = Colors.redAccent]) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4, fontSize: 13)), backgroundColor: backgroundColor, duration: const Duration(seconds: 5)),\n    );\n  }'
  );
  code2 = code2.replaceAll(
    '_showSnackBar("Please fill in all fields");',
    '_showSnackBar(AppErrors.emptyFields);'
  );
  code2 = code2.replaceAll(
    'String errorMsg = "Login Failed. Please try again.";',
    'String errorMsg = AppErrors.genericError;'
  );
  // Using multi-line replace for the specific format
  code2 = code2.replaceAll(
    'errorMsg =\n              "Invalid Login credentials. Please check your Email/ID and Password.";',
    'errorMsg = AppErrors.invalidCredentials;'
  );
  code2 = code2.replaceAll(
    'errorMsg =\n                "Invalid Login credentials. Please check your Email/ID and Password.";',
    'errorMsg = AppErrors.invalidCredentials;'
  );
  code2 = code2.replaceAll(
    'errorMsg = "Incorrect password. Please try again.";',
    'errorMsg = AppErrors.incorrectPassword;'
  );
  code2 = code2.replaceAll(
    'errorMsg = "Too many attempts. Account temporarily locked.";',
    'errorMsg = AppErrors.tooManyRequests;'
  );
  code2 = code2.replaceAll(
    '_showSnackBar("A technical error occurred. Please try again later or contact Admin.");',
    '_showSnackBar(AppErrors.genericError);'
  );
  code2 = code2.replaceAll(
    '_showSnackBar("Mobile number not found. Please contact Admin.");',
    '_showSnackBar(AppErrors.mobileNotFound);'
  );
  code2 = code2.replaceAll(
    "_showSnackBar('Phone verification failed. Please try again later or contact Admin.');",
    "_showSnackBar(AppErrors.genericError);"
  );
  code2 = code2.replaceAll(
    '_showSnackBar("An unexpected error occurred during login. Please contact Admin.");',
    '_showSnackBar(AppErrors.genericError);'
  );
  code2 = code2.replaceAll(
    "_showSnackBar('Invalid SMS Code. Please try again.');",
    "_showSnackBar(AppErrors.invalidOtp);"
  );
  code2 = code2.replaceAll(
    '_showSnackBar("Login Successful!");',
    '_showSnackBar("Login Successful!", Colors.green);'
  );
  code2 = code2.replaceAll(
    '_showSnackBar("Sending SMS to \$mobileNumber...");',
    '_showSnackBar("Sending SMS to \$mobileNumber...", Colors.green);'
  );
  f2.writeAsStringSync(code2);
  
  // Register screen
  var f3 = File('lib/features/auth/register_screen.dart');
  var code3 = f3.readAsStringSync();
  if (!code3.contains('app_errors.dart')) {
    code3 = "import '../../core/utils/app_errors.dart';\n" + code3;
  }
  code3 = code3.replaceAll(
    'void _showSnackBar(String message, Color backgroundColor) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message), backgroundColor: backgroundColor),\n    );\n  }',
    'void _showSnackBar(String message, [Color backgroundColor = Colors.redAccent]) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4, fontSize: 13)), backgroundColor: backgroundColor, duration: const Duration(seconds: 5)),\n    );\n  }'
  );
  code3 = code3.replaceAll(
    '_showSnackBar("Please fill in all fields", Colors.redAccent);',
    '_showSnackBar(AppErrors.emptyFields);'
  );
  code3 = code3.replaceAll(
    '_showSnackBar("Error: \${e.toString()}", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code3 = code3.replaceAll(
    "_showSnackBar(e.message ?? 'An error occurred', Colors.redAccent);",
    "_showSnackBar(e.code == 'too-many-requests' ? AppErrors.tooManyRequests : AppErrors.genericError);"
  );
  f3.writeAsStringSync(code3);
  
  // Forgot password screen
  var f4 = File('lib/features/auth/forgot_password_screen.dart');
  var code4 = f4.readAsStringSync();
  if (!code4.contains('app_errors.dart')) {
    code4 = "import '../../core/utils/app_errors.dart';\n" + code4;
  }
  code4 = code4.replaceAll(
    'void _showSnackBar(String message, Color color) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(\n        content: Text(message),\n        backgroundColor: color,\n      ),\n    );\n  }',
    'void _showSnackBar(String message, [Color backgroundColor = Colors.redAccent]) {\n    ScaffoldMessenger.of(context).showSnackBar(\n      SnackBar(content: Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4, fontSize: 13)), backgroundColor: backgroundColor, duration: const Duration(seconds: 5)),\n    );\n  }'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("Please enter your Membership Number.", Colors.redAccent);',
    '_showSnackBar(AppErrors.emptyFields);'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("Membership Number not found.", Colors.redAccent);',
    '_showSnackBar(AppErrors.memberNotFound);'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("No email associated with this Membership Number.", Colors.redAccent);',
    '_showSnackBar(AppErrors.memberNotFound);'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("Error: \${e.message}", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("An error occurred. Please try again.", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  code4 = code4.replaceAll(
    '_showSnackBar("Error: \${e.toString()}", Colors.redAccent);',
    '_showSnackBar(AppErrors.genericError);'
  );
  f4.writeAsStringSync(code4);
}
