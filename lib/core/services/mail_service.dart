import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class MailService {
  // TODO: Replace with your Domain Email SMTP Details
  static const String _smtpHost = 'aiaprtd.lk'; 
  static const int _smtpPort = 465; 
  static const String _username = 'support@aiaprtd.lk';
  static const String _password = r'Sri12Lanka@#'; // ඔයාගේ Email එකේ Password එක මෙතන දාන්න

  static Future<bool> sendOTP({required String toEmail, required String otp}) async {
    // Using a custom SMTP server instead of Gmail
    final smtpServer = SmtpServer(_smtpHost,
        port: _smtpPort,
        username: _username,
        password: _password,
        ssl: _smtpPort == 465); // Enable SSL if port is 465

    final message = Message()
      ..from = const Address(_username, 'AIAPRTD System')
      ..recipients.add(toEmail)
      ..subject = 'AIAPRTD Verification Code'
      ..html = '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Account Verification</h2>
          <p>Your verification code is: <strong>$otp</strong></p>
          <p>Please enter this code in the app to proceed.</p>
          <p><br>Thank you,<br>AIAPRTD Administration</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      debugPrint('Message not sent. \n' + e.toString());
      return false;
    }
  }
}
