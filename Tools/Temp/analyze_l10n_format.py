import json
import re
import os

def analyze_l10n():
    sources_dir = 'Sources'
    strings_file = 'Sources/Localization/Localizable.xcstrings'
    
    if not os.path.exists(strings_file):
        print(f"Error: {strings_file} not found.")
        return

    with open(strings_file, 'r', encoding='utf-8') as f:
        strings_data = json.load(f)
    
    keys_data = strings_data.get('strings', {})
    
    # Improved pattern for trf calls
    trf_pattern = re.compile(r'(?:Localized|L10n(?:\.\w+)?)\.trf\(\s*"([^"]+)"\s*(?:,\s*([^)]+))?\)')
    
    # Improved pattern for placeholders including positional ones like %1$@, %lld, etc.
    ph_pattern = re.compile(r'%(?:[0-9]+\$)?(?:[-+ 0#])?(?:[0-9]+)?(?:\.[0-9]+)?(?:[hljztLq]|ll|hh)?([@dulfxXegEcaAsSp])')

    issues = []
    
    for root, _, files in os.walk(sources_dir):
        for file in files:
            if file.endswith('.swift'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = trf_pattern.finditer(content)
                    for match in matches:
                        key = match.group(1)
                        args_str = match.group(2) or ""
                        
                        args_count = 0
                        if args_str.strip():
                            depth = 0
                            for char in args_str:
                                if char in '([{': depth += 1
                                elif char in ')]}': depth -= 1
                                if char == ',' and depth == 0: args_count += 1
                            args_count += 1
                        
                        if key not in keys_data:
                            issues.append({'file': path, 'key': key, 'type': 'MISSING_KEY', 'details': f'Key not found.'})
                            continue
                        
                        val_zh = keys_data[key].get('localizations', {}).get('zh-Hans', {}).get('stringUnit', {}).get('value', '')
                        if not val_zh:
                            val_zh = keys_data[key].get('localizations', {}).get('en', {}).get('stringUnit', {}).get('value', '')
                        
                        if not val_zh:
                            issues.append({'file': path, 'key': key, 'type': 'NO_VALUE', 'details': f'No value.'})
                            continue
                        
                        placeholders = ph_pattern.findall(val_zh)
                        ph_count = len(placeholders)
                        
                        # Handle positional arguments: if we see %1$@ and %2$@, ph_count is max of positions
                        pos_matches = re.findall(r'%([0-9]+)\$', val_zh)
                        if pos_matches:
                            ph_count = max(int(m) for m in pos_matches)
                        
                        if ph_count != args_count:
                            issues.append({
                                'file': path,
                                'key': key,
                                'type': 'COUNT_MISMATCH',
                                'details': f'Format expects {ph_count} args, but code provides {args_count}. Value: "{val_zh}"'
                            })
                            continue
    
    if not issues:
        print("✅ No localization formatting issues found.")
    else:
        print(f"❌ Found {len(issues)} potential issues:")
        for issue in issues:
            print(f"[{issue['type']}] {issue['key']} in {os.path.basename(issue['file'])}: {issue['details']}")

if __name__ == '__main__':
    analyze_l10n()
