import 'dart:io';

void main() {
  final dir = Directory('D:/src/aiaprtd_member/lib');
  int filesModified = 0;
  
  if (!dir.existsSync()) {
    print('Directory not found');
    return;
  }

  final files = dir.listSync(recursive: true);
  
  for (var entity in files) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      if (content.contains('debugPrint')) {
        String newContent = content;
        
        while (newContent.contains('debugPrint')) {
          int startIndex = newContent.indexOf('debugPrint');
          // Find the opening parenthesis
          int openParenIndex = newContent.indexOf('(', startIndex);
          if (openParenIndex == -1) break; // Should not happen
          
          int parenCount = 1;
          int i = openParenIndex + 1;
          bool inString = false;
          String stringChar = '';
          
          while (i < newContent.length && parenCount > 0) {
            String char = newContent[i];
            
            if (inString) {
              if (char == '\\') {
                i += 2;
                continue;
              }
              if (char == stringChar) {
                inString = false;
              }
            } else {
              if (char == '"' || char == "'") {
                inString = true;
                stringChar = char;
              } else if (char == '(') {
                parenCount++;
              } else if (char == ')') {
                parenCount--;
              }
            }
            i++;
          }
          
          if (parenCount == 0) {
            // Find the semicolon
            int semiIndex = newContent.indexOf(';', i);
            if (semiIndex != -1) {
              // Replace the whole block with spaces to keep line numbers intact (optional) or just remove
              newContent = newContent.replaceRange(startIndex, semiIndex + 1, '');
            } else {
              // Semicolon not found, just break to avoid infinite loop
              break;
            }
          } else {
             break;
          }
        }
        
        if (content != newContent) {
          entity.writeAsStringSync(newContent);
          filesModified++;
          print('Modified ${entity.path}');
        }
      }
    }
  }
  print('Total files modified: $filesModified');
}
