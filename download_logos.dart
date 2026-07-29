import 'dart:io';
import 'dart:convert';

void main() async {
  final urls = {
    'dialog':
        'https://freelogopng.com/images/all_img/1657866761dialog-logo-png.png',
    'mobitel':
        'https://upload.wikimedia.org/wikipedia/en/5/52/Mobitel_%28Sri_Lanka%29_logo.svg', // Will see if we can just get svg or use network
    'airtel':
        'https://logodownload.org/wp-content/uploads/2014/09/airtel-logo-0.png',
    'hutch':
        'https://upload.wikimedia.org/wikipedia/commons/c/cd/Hutch_logo.svg'
  };

  final client = HttpClient();
  client.userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

  for (final entry in urls.entries) {
    try {
      final req = await client.getUrl(Uri.parse(entry.value));
      final res = await req.close();
      if (res.statusCode == 200) {
        final bytes = await res.expand((b) => b).toList();
        final ext = entry.value.endsWith('.svg') ? 'svg' : 'png';
        final file = File('assets/images/${entry.key}_logo.$ext');
        await file.writeAsBytes(bytes);
        print('Saved ${entry.key}.$ext');
      } else {
        print('Error ${entry.key}: Status ${res.statusCode}');
      }
    } catch (e) {
      print('Error ${entry.key}: $e');
    }
  }
  client.close();
}
