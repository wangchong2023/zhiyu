import json
import os

def add_keys(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get('strings', {})
    for key, (zh, en) in new_keys.items():
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": {
                        "stringUnit": {
                            "state": "translated",
                            "value": en
                        }
                    },
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": zh
                        }
                    }
                }
            }
            print(f"Added key: {key}")
    
    data['strings'] = strings
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

new_keys = {
    "sidebar.settings": ("设置", "Settings"),
    "sidebar.settings.placeholder": ("请从中栏选择一个设置项以查看详情", "Please select a setting item from the middle column to view details")
}

add_keys('/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Localizable.xcstrings', new_keys)
