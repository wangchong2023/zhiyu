import json
import os

def fix_settings_l10n(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get('strings', {})
    
    # 1. 重命名缺失前缀的键
    keys_to_rename = {
        "developer.section.data": "settings.developer.section.data",
        "developer.section.performance": "settings.developer.section.performance",
        "developer.section.system": "settings.developer.section.system"
    }
    
    for old_key, new_key in keys_to_rename.items():
        if old_key in strings:
            strings[new_key] = strings.pop(old_key)
            print(f"Renamed {old_key} to {new_key}")
    
    # 2. 添加完全缺失的键
    new_keys = {
        "settings.developer.title": ("开发者选项", "Developer Options"),
        "settings.developer.subtitle": ("数据注入、压力测试与系统重置", "Data injection, stress testing and system reset")
    }
    
    for key, (zh, en) in new_keys.items():
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {
                    "en": { "stringUnit": { "state": "translated", "value": en } },
                    "zh-Hans": { "stringUnit": { "state": "translated", "value": zh } }
                }
            }
            print(f"Added key: {key}")
            
    data['strings'] = strings
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

fix_settings_l10n('/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Settings.xcstrings')
