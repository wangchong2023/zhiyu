import json
import os
import sys

def get_keys_from_xcstrings(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return set(data.get('strings', {}).keys())
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return set()

def main():
    workspace_root = "/Users/constantine/Documents/work/code/projects/ZhiYu"
    localization_dir = os.path.join(workspace_root, "Sources/Localization")
    
    localizable_path = os.path.join(localization_dir, "Localizable.xcstrings")
    if not os.path.exists(localizable_path):
        print("Localizable.xcstrings not found!")
        return

    localizable_keys = get_keys_from_xcstrings(localizable_path)
    print(f"Total keys in Localizable.xcstrings: {len(localizable_keys)}")

    other_keys = set()
    other_files = [f for f in os.listdir(localization_dir) if f.endswith(".xcstrings") and f != "Localizable.xcstrings"]
    
    for filename in other_files:
        path = os.path.join(localization_dir, filename)
        keys = get_keys_from_xcstrings(path)
        other_keys.update(keys)
        # print(f"Loaded {len(keys)} keys from {filename}")

    unique_to_localizable = localizable_keys - other_keys
    missing_from_localizable = other_keys - localizable_keys
    
    print(f"\n[SUMMARY]")
    print(f"Total keys in Localizable.xcstrings: {len(localizable_keys)}")
    print(f"Total keys in specialized tables: {len(other_keys)}")
    print(f"Keys found ONLY in Localizable.xcstrings: {len(unique_to_localizable)}")
    print(f"Keys found in specialized tables but MISSING from Localizable: {len(missing_from_localizable)}")

    if unique_to_localizable:
        print(f"\n[ONLY IN LOCALIZABLE] (Candidates for categorization):")
        for key in sorted(unique_to_localizable):
            if key.strip():
                print(f"  - {key}")

    if missing_from_localizable:
        print(f"\n[MISSING FROM LOCALIZABLE] (Risk of fallback failure):")
        for key in sorted(missing_from_localizable):
            if key.strip():
                print(f"  - {key}")

if __name__ == "__main__":
    main()
