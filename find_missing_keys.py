import os
import re
import json

# 1. Load all keys from .xcstrings
xcstrings_keys = set()
catalogs_dir = 'Sources/Localization/Catalogs'
for file in os.listdir(catalogs_dir):
    if file.endswith('.xcstrings'):
        with open(os.path.join(catalogs_dir, file), 'r', encoding='utf-8') as f:
            data = json.load(f)
            strings = data.get('strings', {})
            for key in strings.keys():
                xcstrings_keys.add(key)

# 2. Find all keys referenced in L10n extensions
referenced_keys = set()
tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
tr_func_pattern = re.compile(r'trf?\(\s*"([^"]+)"') # For local tr() calls in L10n+XXX.swift

extensions_dir = 'Sources/Localization/Extensions'
missing = []

for file in os.listdir(extensions_dir):
    if file.endswith('.swift'):
        path = os.path.join(extensions_dir, file)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            # find all string literals passed to tr or Localized.tr
            matches1 = tr_pattern.findall(content)
            matches2 = tr_func_pattern.findall(content)
            
            for key in set(matches1 + matches2):
                if key not in xcstrings_keys:
                    missing.append((path, key))

for p, k in missing:
    print(f"Missing in catalog: {k} (referenced in {p})")
