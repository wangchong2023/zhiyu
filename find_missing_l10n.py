import os
import re
import json

def find_missing_keys():
    # Load xcstrings
    xcstrings_path = "Sources/Localization/Localizable.xcstrings"
    with open(xcstrings_path, 'r') as f:
        data = json.load(f)
        keys = set(data.get("strings", {}).keys())
    
    # Grep for Localized.tr or Localized.trf or L10n.something.tr
    # We'll just look for .tr("...") and .trf("...", ...)
    missing = set()
    found_keys = set()
    
    for root, dirs, files in os.walk("Sources"):
        for file in files:
            if file.endswith(".swift"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                    # Pattern for .tr("key") or .trf("key", ...)
                    # Also L10n.Table.tr("key")
                    matches = re.findall(r'\.tr(?:f)?\("([^"]+)"', content)
                    for key in matches:
                        found_keys.add(key)
                        if key not in keys:
                            # Check if it's in other tables?
                            # For simplicity, we just check Localizable first
                            missing.add((key, path))
    
    print(f"Total keys found in code: {len(found_keys)}")
    print(f"Missing keys (not in Localizable.xcstrings):")
    for key, path in sorted(missing):
        # Filter out common prefixes that might be in other tables
        if not any(key.startswith(p) for p in ["AI.", "Common.", "Settings.", "Dashboard.", "Lint.", "Ingest."]):
            print(f"  {key} (in {path})")

if __name__ == "__main__":
    find_missing_keys()
