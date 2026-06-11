import json
import glob

# Fix stale keys
for file in glob.glob("Sources/Localization/Catalogs/*.xcstrings"):
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    changed = False
    for key, value in data.get('strings', {}).items():
        if value.get('extractionState') == 'stale':
            value['extractionState'] = 'manual'
            changed = True
    if changed:
        with open(file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

