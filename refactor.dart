import 'dart:io';

void main() {
  final baseDir = Directory('C:/src/aiaprtd_member/lib');
  const packageName = 'aiaprtd_member';

  final moveMap = {
    // Core
    'providers': 'core/providers',
    'utils': 'core/utils',
    'notification_service.dart': 'core/services/notification_service.dart',
    'check_polls.dart': 'core/services/check_polls.dart',
    
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

    // Auth & Root screens
    'auth_service.dart': 'features/auth/auth_service.dart',
    'login_screen.dart': 'features/auth/login_screen.dart',
    'register_screen.dart': 'features/auth/register_screen.dart',
    'forgot_password_screen.dart': 'features/auth/forgot_password_screen.dart',
    'first_time_login_screen.dart': 'features/auth/first_time_login_screen.dart',
    'splash_screen.dart': 'features/auth/splash_screen.dart',
    'privacy_policy_screen.dart': 'features/settings/privacy_policy_screen.dart',
    'terms_conditions_screen.dart': 'features/settings/terms_conditions_screen.dart',
  };

  String posixPath(String p) => p.replaceAll('\\', '/');

  // 1. Convert all relative imports to absolute imports
  final allDartFiles = baseDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (var file in allDartFiles) {
    try {
      var lines = file.readAsLinesSync();
      var newLines = <String>[];
      
      for (var line in lines) {
        if (line.trim().startsWith('import ') && !line.contains('package:') && !line.contains('dart:')) {
          final regex = RegExp(r"import\s+['\u0022](.*?)['\u0022](.*)");
          final match = regex.firstMatch(line);
          if (match != null) {
            var relImport = match.group(1)!;
            var suffix = match.group(2)!;
            
            var targetFile = File('${posixPath(file.parent.path)}/$relImport').absolute;
            var targetPath = posixPath(targetFile.path);
            var basePath = posixPath(baseDir.absolute.path);
            
            if (targetPath.startsWith(basePath)) {
              var absImport = targetPath.replaceFirst('$basePath/', '');
              line = "import 'package:$packageName/$absImport'$suffix";
            }
          }
        }
        newLines.add(line);
      }
      file.writeAsStringSync(newLines.join('\n'));
    } catch (e) {
      print('Error in file ${file.path}: $e');
    }
  }
  print('Converted to absolute imports.');

  // 2. Build file mappings
  final fileMappings = <String, String>{};
  for (var entry in moveMap.entries) {
    var oldPath = entry.key;
    var newPath = entry.value;
    
    var oldFull = File('${baseDir.path}/$oldPath');
    var oldDir = Directory('${baseDir.path}/$oldPath');
    
    if (oldDir.existsSync()) {
      for (var file in oldDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        var relPath = posixPath(file.path).replaceFirst('${posixPath(oldDir.path)}/', '');
        fileMappings['$oldPath/$relPath'] = '$newPath/$relPath';
      }
    } else if (oldFull.existsSync()) {
      fileMappings[oldPath] = newPath;
    }
  }

  // 3. Move files
  for (var entry in moveMap.entries) {
    var srcPath = '${baseDir.path}/${entry.key}';
    var dstPath = '${baseDir.path}/${entry.value}';
    
    if (Directory(srcPath).existsSync()) {
      var dstDir = Directory(dstPath);
      if (!dstDir.existsSync()) dstDir.createSync(recursive: true);
      
      // Moving directories directly in Dart can be tricky across drives, but fine here
      // Process.runSync('cmd', ['/c', 'move', posixPath(srcPath).replaceAll('/', '\\'), posixPath(dstPath).replaceAll('/', '\\')]);
      var srcDir = Directory(srcPath);
      for(var item in srcDir.listSync(recursive: true)) {
        if(item is File) {
            var relativeItemPath = posixPath(item.path).replaceFirst('${posixPath(srcDir.path)}/', '');
            var newItemPath = '$dstPath/$relativeItemPath';
            var newFile = File(newItemPath);
            if(!newFile.parent.existsSync()) newFile.parent.createSync(recursive: true);
            item.copySync(newFile.path);
            item.deleteSync();
        }
      }
      srcDir.deleteSync(recursive: true);
    } else if (File(srcPath).existsSync()) {
      var dstFile = File(dstPath);
      if (!dstFile.parent.existsSync()) dstFile.parent.createSync(recursive: true);
      File(srcPath).renameSync(dstFile.path);
    }
  }
  print('Moved files.');

  // 4. Update absolute imports
  final movedDartFiles = baseDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (var file in movedDartFiles) {
    try {
      var lines = file.readAsLinesSync();
      var newLines = <String>[];
      
      for (var line in lines) {
        if (line.trim().startsWith('import ')) {
          final regex = RegExp(r"import\s+['\u0022]package:aiaprtd_member/(.*?)['\u0022](.*)");
          final match = regex.firstMatch(line);
          if (match != null) {
            var importPath = match.group(1)!;
            var suffix = match.group(2)!;
            
            if (fileMappings.containsKey(importPath)) {
              var newPath = fileMappings[importPath];
              line = "import 'package:$packageName/$newPath'$suffix";
            }
          }
        }
        newLines.add(line);
      }
      file.writeAsStringSync(newLines.join('\n'));
    } catch (e) {
      print('Error in file ${file.path}: $e');
    }
  }
  print('Updated absolute imports.');
}
