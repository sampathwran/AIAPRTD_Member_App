import 'dart:io';
import 'package:image/image.dart';

void main() {
  final file = File('C:/src/aiaprtd_member/assets/images/logo.png');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  
  final imageBytes = file.readAsBytesSync();
  final image = decodeImage(imageBytes);
  if (image == null) return;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r > 240 && pixel.g > 240 && pixel.b > 240) {
        image.setPixelRgba(x, y, 255, 255, 255, 0);
      }
    }
  }

  File('C:/src/aiaprtd_member/assets/images/logo.png').writeAsBytesSync(encodePng(image));
  print('Done');
}
