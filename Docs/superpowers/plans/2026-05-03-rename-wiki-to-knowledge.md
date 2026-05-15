# Localization Rename (Wiki to Knowledge) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Update all localization files and code references to replace "Wiki" with "Knowledge" and "维基" with "知识库".

**Architecture:** Use a Python script to surgically update `.xcstrings` files (JSON) to avoid breaking structure, then use global search and replace for Swift code references.

**Tech Stack:** Python (for JSON processing), Shell (for mass replacement).

---

### Task 1: Research and Script Preparation

**Files:**
- Create: `Tools/Temp/rename_wiki_to_knowledge.py`

- [x] **Step 1: Create a Python script to process .xcstrings files**

```python
import json
import os
import re

def rename_content(text):
    if not isinstance(text, str):
        return text
    
    # English replacements
    text = text.replace("New Wiki Page", "New Page")
    text = text.replace("Wiki Link", "Knowledge Link")
    text = text.replace("Import to Wiki", "Import to Knowledge Base")
    text = text.replace("Ask your wiki", "Ask your knowledge base")
    text = text.replace("Wiki", "Knowledge")
    text = text.replace("wiki", "knowledge")
    
    # Chinese replacements
    text = text.replace("维基", "知识库")
    
    return text

def rename_key(key):
    # Rename keys containing wiki
    new_key = key.replace("wiki", "knowledge").replace("Wiki", "Knowledge")
    return new_key

loc_dir = "Sources/Localization"
files = [f for f in os.listdir(loc_dir) if f.endswith(".xcstrings")]

key_mapping = {}

for filename in files:
    path = os.path.join(loc_dir, filename)
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if "strings" not in data:
        continue
    
    new_strings = {}
    for key, value in data["strings"].items():
        new_key = rename_key(key)
        if new_key != key:
            key_mapping[key] = new_key
        
        # Process localizations
        if "localizations" in value:
            for lang, loc_data in value["localizations"].items():
                if "stringUnit" in loc_data and "value" in loc_data["stringUnit"]:
                    loc_data["stringUnit"]["value"] = rename_content(loc_data["stringUnit"]["value"])
                if "variations" in loc_data:
                    # Handle pluralization or other variations if any
                    pass
        
        new_strings[new_key] = value
    
    data["strings"] = new_strings
    
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Save key mapping for code updates
with open("Tools/Temp/key_mapping.json", 'w', encoding='utf-8') as f:
    json.dump(key_mapping, f, ensure_ascii=False, indent=2)

print(f"Processed {len(files)} files.")
print(f"Key replacements found: {len(key_mapping)}")
```

- [x] **Step 2: Run the script to update .xcstrings**

Run: `python3 Tools/Temp/rename_wiki_to_knowledge.py`

### Task 2: Update Swift Code References

**Files:**
- Modify: All relevant `.swift` files in `Sources/`

- [x] **Step 1: Read key mapping and apply to Swift files**

Create a temporary script to update Swift files based on `key_mapping.json`.

```python
import json
import os

with open("Tools/Temp/key_mapping.json", 'r') as f:
    mapping = json.load(f)

# Sort mapping by key length descending to avoid partial replacements
sorted_keys = sorted(mapping.keys(), key=len, reverse=True)

def update_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old_key in sorted_keys:
        new_key = mapping[old_key]
        
        # Keys in xcstrings like "editor.wikiLink" are used in L10n as tr("wikiLink")
        # or in Localized.tr("editor.wikiLink")
        
        # 1. Direct key replacement for Localized.tr
        new_content = new_content.replace(f'"{old_key}"', f'"{new_key}"')
        
        # 2. Handle L10n style tr("wikiLink") where the prefix is stripped
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
for root, dirs, files in os.walk("Sources"):
    for file in files:
        if file.endswith(".swift"):
            path = os.path.join(root, file)
            if update_file(path):
                print(f"Updated {path}")
```

- [x] **Step 2: Run the Swift update script**

Run the script created in Step 1.

### Task 3: Final Synchronization and Cleanup

- [x] **Step 1: Run the localization synchronization script**

Run: `python3 Tools/update_localization.py`

- [x] **Step 2: Verify no build errors**

Run: `xcodebuild build -project KM.xcodeproj -scheme KM -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`

- [x] **Step 3: Cleanup temporary scripts**

Run: `rm Tools/Temp/rename_wiki_to_knowledge.py Tools/Temp/key_mapping.json Tools/Temp/update_swift_keys.py`
