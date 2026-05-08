import json
import os

def sync_localization():
    workspace_root = "/Users/constantine/Documents/work/code/projects/ZhiYu"
    localization_dir = os.path.join(workspace_root, "Sources/Localization")
    
    localizable_path = os.path.join(localization_dir, "Localizable.xcstrings")
    if not os.path.exists(localizable_path):
        print("Localizable.xcstrings not found!")
        return

    with open(localizable_path, 'r', encoding='utf-8') as f:
        localizable_data = json.load(f)
    
    localizable_strings = localizable_data.get('strings', {})
    
    other_files = [f for f in os.listdir(localization_dir) if f.endswith(".xcstrings") and f != "Localizable.xcstrings"]
    
    added_count = 0
    for filename in other_files:
        path = os.path.join(localization_dir, filename)
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            strings = data.get('strings', {})
            for key, value in strings.items():
                if key not in localizable_strings:
                    localizable_strings[key] = value
                    added_count += 1
                    print(f"Adding key: {key} from {filename}")

    if added_count > 0:
        localizable_data['strings'] = localizable_strings
        # 按键名排序以保持文件整洁
        sorted_strings = dict(sorted(localizable_strings.items()))
        localizable_data['strings'] = sorted_strings
        
        with open(localizable_path, 'w', encoding='utf-8') as f:
            json.dump(localizable_data, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully added {added_count} missing keys to Localizable.xcstrings")
    else:
        print("\nNo missing keys found to sync.")

if __name__ == "__main__":
    sync_localization()
