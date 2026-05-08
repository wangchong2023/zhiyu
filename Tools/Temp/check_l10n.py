import json
import os
import glob

def check_missing_en(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print(f"Error decoding {file_path}")
            return []
            
    missing_keys = []
    strings = data.get('strings', {})
    for key, content in strings.items():
        localizations = content.get('localizations', {})
        if 'en' not in localizations:
            missing_keys.append(key)
        else:
            en_val = localizations['en'].get('stringUnit', {}).get('value', "")
            if not en_val:
                missing_keys.append(f"{key} (empty value)")
    return missing_keys

all_xcstrings = glob.glob('Sources/Localization/*.xcstrings')
total_missing = 0

for path in all_xcstrings:
    missing = check_missing_en(path)
    if missing:
        print(f"File: {path}")
        for m in missing:
            print(f"  - {m}")
        total_missing += len(missing)

print(f"\nTotal missing English localizations: {total_missing}")
