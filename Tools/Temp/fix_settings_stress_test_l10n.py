import json
import os

def update_settings_l10n(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get('strings', {})
    
    # 添加压测相关的本地化文案
    new_keys = {
        "settings.developer.stressTest.1k": ("压力测试 (1000 节点)", "Stress Test (1000 nodes)"),
        "settings.developer.stressTest.10k": ("极限压测 (10000 节点)", "Extreme Stress Test (10000 nodes)"),
        "settings.developer.stressTest.success": ("成功生成 %d 个压力测试节点", "Successfully generated %d stress test nodes"),
        "settings.developer.stressTest.confirmTitle": ("执行压力测试", "Run Stress Test"),
        "settings.developer.stressTest.confirmAction": ("确定 (清空数据并生成 %d 节点)", "Confirm (Clear data and generate %d nodes)"),
        "settings.developer.stressTest.confirmMessage": ("此操作将清空当前数据库所有页面，仅用于性能测试。10000 节点可能会导致短时间卡顿。", "This operation will clear all pages in the current database, used for performance testing only. 10000 nodes may cause brief stuttering.")
    }
    
    for key, (zh, en) in new_keys.items():
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                "en": { "stringUnit": { "state": "translated", "value": en } },
                "zh-Hans": { "stringUnit": { "state": "translated", "value": zh } }
            }
        }
        print(f"Updated key: {key}")
            
    data['strings'] = strings
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_settings_l10n('/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Settings.xcstrings')
