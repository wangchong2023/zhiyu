#!/usr/bin/env python3
import json
import os
import re

def is_chinese(text):
    if not text: return False
    return any(ord(c) > 127 for c in text)

def audit_xcstrings():
    catalogs_dir = 'Sources/Localization/Catalogs'
    if not os.path.exists(catalogs_dir):
        print(f"Error: {catalogs_dir} not found")
        return

    files = [f for f in os.listdir(catalogs_dir) if f.endswith('.xcstrings')]
    
    overall_issues = 0
    
    for file in files:
        path = os.path.join(catalogs_dir, file)
        with open(path, 'r') as f:
            data = json.load(f)
        
        strings = data.get('strings', {})
        file_issues = []
        
        for key, value in strings.items():
            locs = value.get('localizations', {})
            en_loc = locs.get('en', {}).get('stringUnit', {})
            zh_loc = locs.get('zh-Hans', {}).get('stringUnit', {})
            
            en_val = en_loc.get('value', '')
            zh_val = zh_loc.get('value', '')
            zh_state = zh_loc.get('state', '')
            
            # 1. Missing zh-Hans entirely
            if 'zh-Hans' not in locs:
                if not key.strip() or re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', key):
                    continue # Skip pure format/empty keys
                file_issues.append(f"  [MISSING] Key: \"{key}\" has no zh-Hans localization")
            
            # 2. zh-Hans is same as en (and en is actually English)
            elif en_val == zh_val and not is_chinese(en_val) and en_val.strip() != '':
                if re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', en_val):
                    continue # Skip formats
                file_issues.append(f"  [SAME] Key: \"{key}\", Value: \"{en_val}\" (English value used for Chinese)")
            
            # 3. en contains Chinese (Incorrect source entry)
            elif is_chinese(en_val) and not is_chinese(zh_val):
                 file_issues.append(f"  [SRC_ERR] Key: \"{key}\", English field contains Chinese: \"{en_val}\"")

            # 4. zh-Hans state is not translated
            elif zh_state and zh_state != 'translated':
                 file_issues.append(f"  [STATE] Key: \"{key}\", zh-Hans state is \"{zh_state}\" (potential stale translation)")

        if file_issues:
            print(f"\n📂 {file}")
            for issue in file_issues:
                print(issue)
            overall_issues += len(file_issues)
            
    print(f"\nTotal L10n issues found: {overall_issues}")
    return overall_issues

if __name__ == '__main__':
    audit_xcstrings()
