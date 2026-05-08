import json
import os
import glob

def find_duplicates():
    base_path = "Sources/Localization"
    files = glob.glob(os.path.join(base_path, "*.xcstrings"))
    
    key_map = {} # key -> list of files
    
    for file_path in files:
        # 排除 Localizable.xcstrings，因为它是汇总表
        if "Localizable.xcstrings" in file_path:
            continue
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                strings = data.get("strings", {})
                for key in strings.keys():
                    if key not in key_map:
                        key_map[key] = []
                    key_map[key].append(os.path.basename(file_path))
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
                
    duplicates = {k: v for k, v in key_map.items() if len(v) > 1}
    
    if not duplicates:
        print("未发现跨模块（排除 Localizable.xcstrings）重复的键值。")
    else:
        print("发现以下重复的键值：")
        for key, files in duplicates.items():
            print(f"- {key}: {', '.join(files)}")

if __name__ == "__main__":
    find_duplicates()
