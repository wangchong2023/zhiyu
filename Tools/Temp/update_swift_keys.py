import json
import os

mapping_path = "Tools/Temp/key_mapping.json"
if not os.path.exists(mapping_path):
    print("Mapping file not found.")
    exit(1)

with open(mapping_path, 'r') as f:
    mapping = json.load(f)

# Sort mapping by key length descending to avoid partial replacements
sorted_keys = sorted(mapping.keys(), key=len, reverse=True)

def update_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old_key in sorted_keys:
        new_key = mapping[old_key]
        
        # 1. Direct key replacement for Localized.tr or quoted strings
        new_content = new_content.replace(f'"{old_key}"', f'"{new_key}"')
        
        # 2. Handle L10n style tr("wikiLink") where the prefix is stripped
        # e.g., mapping "editor.wikiLink" -> "editor.knowledgeLink"
        # We need to replace tr("wikiLink") with tr("knowledgeLink")
        if "." in old_key:
            prefix, short_key = old_key.split(".", 1)
            new_prefix, new_short_key = new_key.split(".", 1)
            new_content = new_content.replace(f'tr("{short_key}")', f'tr("{new_short_key}")')
            new_content = new_content.replace(f'trf("{short_key}"', f'trf("{new_short_key}"')

    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

# Walk through Sources
update_count = 0
for root, dirs, files in os.walk("Sources"):
    for file in files:
        if file.endswith(".swift"):
            path = os.path.join(root, file)
            if update_file(path):
                print(f"Updated {path}")
                update_count += 1

print(f"Total files updated: {update_count}")
