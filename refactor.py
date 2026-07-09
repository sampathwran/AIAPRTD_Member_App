import os
import shutil
import re
from pathlib import Path

BASE_DIR = Path(r"C:\src\aiaprtd_member\lib")
PACKAGE_NAME = "aiaprtd_member"

move_map = {
    # Core
    "providers": "core/providers",
    "utils": "core/utils",
    "notification_service.dart": "core/services/notification_service.dart",
    "check_polls.dart": "core/services/check_polls.dart",
    
    # Features
    "home": "features/home",
    "ads": "features/marketplace",
    "earnings": "features/earnings",
    "finance": "features/finance",
    "income": "features/income",
    "general": "features/general",
    "membership_fee": "features/membership_fee",
    "parking": "features/parking",
    "personal_info": "features/personal_info",
    "profile": "features/profile",
    "settings": "features/settings",
    "vehicle_info": "features/vehicle_info",

    # Auth & Root screens
    "auth_service.dart": "features/auth/auth_service.dart",
    "login_screen.dart": "features/auth/login_screen.dart",
    "register_screen.dart": "features/auth/register_screen.dart",
    "forgot_password_screen.dart": "features/auth/forgot_password_screen.dart",
    "first_time_login_screen.dart": "features/auth/first_time_login_screen.dart",
    "splash_screen.dart": "features/auth/splash_screen.dart",
    "privacy_policy_screen.dart": "features/settings/privacy_policy_screen.dart",
    "terms_conditions_screen.dart": "features/settings/terms_conditions_screen.dart",
}

# 1. We must read all files and convert ALL relative imports to absolute imports BEFORE moving them!
def convert_to_absolute_imports():
    for filepath in BASE_DIR.rglob('*.dart'):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            new_lines = []
            file_rel_path = filepath.relative_to(BASE_DIR).as_posix()
            
            for line in lines:
                if line.strip().startswith('import ') and "package:" not in line and "dart:" not in line:
                    match = re.search(r"import\s+['\"](.*?)['\"](.*)", line)
                    if match:
                        rel_import = match.group(1)
                        suffix = match.group(2)
                        
                        # Resolve relative import
                        current_dir = filepath.parent
                        target_file = (current_dir / rel_import).resolve()
                        
                        try:
                            # Try to make it relative to BASE_DIR
                            abs_import = target_file.relative_to(BASE_DIR).as_posix()
                            new_line = f"import 'package:{PACKAGE_NAME}/{abs_import}'{suffix}"
                            line = new_line
                        except ValueError:
                            pass # Not inside lib, ignore
                
                new_lines.append(line)
                
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))
        except Exception as e:
            print(f"Error updating imports in {filepath}: {e}")

convert_to_absolute_imports()
print("Converted imports to absolute.")

# 2. Build mapping of old paths to new paths
file_mappings = {}
def build_file_mappings():
    for old_path, new_path in move_map.items():
        old_full = BASE_DIR / old_path
        new_full = BASE_DIR / new_path
        
        if old_full.is_dir():
            for filepath in old_full.rglob('*.dart'):
                rel_path = filepath.relative_to(old_full)
                file_mappings[filepath.relative_to(BASE_DIR).as_posix()] = (new_full / rel_path).relative_to(BASE_DIR).as_posix()
        elif old_full.is_file():
            file_mappings[old_full.relative_to(BASE_DIR).as_posix()] = new_full.relative_to(BASE_DIR).as_posix()

build_file_mappings()

# 3. Move files
def move_files():
    for old_path, new_path in move_map.items():
        src = BASE_DIR / old_path
        dst = BASE_DIR / new_path
        
        if not src.exists():
            continue
            
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))

move_files()
print("Moved files.")

# 4. Update absolute imports with new paths
def update_absolute_imports():
    for filepath in BASE_DIR.rglob('*.dart'):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            new_lines = []
            
            for line in lines:
                if line.strip().startswith('import '):
                    match = re.search(r"import\s+['\"]package:aiaprtd_member/(.*?)['\"](.*)", line)
                    if match:
                        import_path = match.group(1)
                        suffix = match.group(2)
                        
                        if import_path in file_mappings:
                            new_path = file_mappings[import_path]
                            line = f"import 'package:{PACKAGE_NAME}/{new_path}'{suffix}"
                
                new_lines.append(line)
                
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))
        except Exception as e:
            print(f"Error updating absolute imports in {filepath}: {e}")

update_absolute_imports()
print("Updated absolute imports.")
