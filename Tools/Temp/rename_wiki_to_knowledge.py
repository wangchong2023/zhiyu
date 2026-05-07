import json
import os
import re

def rename_content(text):
    if not isinstance(text, str):
        return text
    
    # English replacements (order matters, more specific first)
    text = text.replace("New Wiki Page", "New Page")
    text = text.replace("Wiki Link", "Knowledge Link")
    text = text.replace("Wiki link", "Knowledge link")
    text = text.replace("wiki link", "knowledge link")
    text = text.replace("Import to Wiki", "Import to Knowledge Base")
    text = text.replace("Ask your wiki", "Ask your knowledge base")
    text = text.replace("Save to Wiki", "Save to Knowledge")
    text = text.replace("Ingest to Wiki", "Ingest to Knowledge")
    text = text.replace("Wiki stats", "Knowledge stats")
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
    print(f"Processing {filename}...")
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
                    # For simplicity, we just look for 'value' in nested structures if they exist
                    # (Though xcstrings usually use stringUnit for simple cases)
                    pass
        
        new_strings[new_key] = value
    
    data["strings"] = new_strings
    
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Save key mapping for code updates
mapping_path = "Tools/Temp/key_mapping.json"
os.makedirs(os.path.dirname(mapping_path), exist_ok=True)
with open(mapping_path, 'w', encoding='utf-8') as f:
    json.dump(key_mapping, f, ensure_ascii=False, indent=2)

print(f"Processed {len(files)} files.")
print(f"Key replacements found: {len(key_mapping)}")
