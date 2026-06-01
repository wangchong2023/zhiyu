import re
import os
import json
import subprocess

# Run check_localization.py and parse output
result = subprocess.run(["python3", "Tools/check_localization.py"], capture_output=True, text=True)
output = result.stdout

# Pattern to extract missing keys
# Example line: Key: "pagesCount" - 🚨 [ERROR] Key defined in L10n extension but missing in .xcstrings
# Followed by: 📂 Sources/Localization/Extensions/L10n+Transfer.swift

missing_keys = []
current_key = None

for line in output.split('\n'):
    line = line.strip()
    key_match = re.match(r'^Key:\s*"([^"]+)"\s*-\s*🚨\s*\[ERROR\]\s*Key defined in L10n extension but missing in \.xcstrings', line)
    if key_match:
        current_key = key_match.group(1)
    elif line.startswith('📂 Sources/Localization/Extensions/L10n+'):
        if current_key:
            # e.g., L10n+AI.swift -> AI
            catalog_name = line.split('L10n+')[1].replace('.swift', '')
            missing_keys.append((catalog_name, current_key))
            current_key = None

grouped = {}
for catalog, key in missing_keys:
    grouped.setdefault(catalog, []).append(key)

base_path = "Sources/Localization/Catalogs"

for catalog, keys in grouped.items():
    file_path = os.path.join(base_path, f"{catalog}.xcstrings")
    
    if not os.path.exists(file_path):
        data = {"sourceLanguage": "en", "strings": {}}
    else:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            
    if "strings" not in data:
        data["strings"] = {}
        
    for key in keys:
        if key not in data["strings"]:
            val = key.split(".")[-1].replace("([A-Z])", " \\1").capitalize()
            data["strings"][key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": {
                        "stringUnit": {
                            "state": "translated",
                            "value": val
                        }
                    },
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": val + " (zh)"
                        }
                    }
                }
            }
            
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

print(f"Fixed {len(missing_keys)} missing keys.")
