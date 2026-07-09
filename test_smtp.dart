import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  final smtpServer = SmtpServer('mail.aiaprtd.lk', port: 465, username: 'support@aiaprtd.lk', password: r'Sri12Lanka#$', ssl: true);
  final message = Message()
    ..from = const Address('support@aiaprtd.lk', 'Test')
    ..recipients.add('wijesingherans@gmail.com')
    ..text = 'This is a test';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } catch (e) {
    print('Message not sent.');
    print(e.toString());
  }
}

