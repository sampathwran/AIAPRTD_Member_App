import 'dart:io';

void main() {
  final baseDir = Directory('C:/src/aiaprtd_member/lib');
  
  final fileMappings = {
    // Core
    'providers': 'core/providers',
    'utils': 'core/utils',
    
    // Features
    'home': 'features/home',
    'ads': 'features/marketplace',
    'earnings': 'features/earnings',
    'finance': 'features/finance',
    'income': 'features/income',
    'general': 'features/general',
    'membership_fee': 'features/membership_fee',
    'parking': 'features/parking',
    'personal_info': 'features/personal_info',
    'profile': 'features/profile',
    'settings': 'features/settings',
    'vehicle_info': 'features/vehicle_info',
  };

  final allDartFiles = baseDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (var file in allDartFiles) {
    try {
      var lines = file.readAsLinesSync();
      var newLines = <String>[];
      var modified = false;
      
      for (var line in lines) {
        if (line.trim().startsWith('import ') && line.contains('package:aiaprtd_member/') && line.contains('../')) {
          // Resolve something like package:aiaprtd_member/home/../providers/booking_provider.dart
          // to package:aiaprtd_member/core/providers/booking_provider.dart
          
          final regex = RegExp(r"import\s+['\u0022]package:aiaprtd_member/(.*?)['\u0022](.*)");
          final match = regex.firstMatch(line);
          if (match != null) {
            var importPath = match.group(1)!;
            var suffix = match.group(2)!;
            
            // manually normalize the path
            var parts = importPath.split('/');
            var resolvedParts = <String>[];
            for (var part in parts) {
              if (part == '..') {
                if (resolvedParts.isNotEmpty) resolvedParts.removeLast();
              } else if (part != '.') {
                resolvedParts.add(part);
              }
            }
            
            var resolvedPath = resolvedParts.join('/');
            
            // Now apply the mapping if needed (because the original script mapped BEFORE normalizing)
            var mappedPath = resolvedPath;
            for (var entry in fileMappings.entries) {
              if (resolvedPath.startsWith('${entry.key}/')) {
                mappedPath = resolvedPath.replaceFirst('${entry.key}/', '${entry.value}/');
                break;
              }
            }
            
            line = "import 'package:aiaprtd_member/$mappedPath'$suffix";
            modified = true;
          }
        }
        newLines.add(line);
      }
      if (modified) {
        file.writeAsStringSync(newLines.join('\n'));
      }
    } catch (e) {
      print('Error in file ${file.path}: $e');
    }
  }
  print('Fixed imports.');
}
