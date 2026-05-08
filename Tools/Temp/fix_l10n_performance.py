import json
import os

file_path = '/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Localizable.xcstrings'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

s = data["strings"]

def set_val(key, zh, en):
    if key not in s:
        s[key] = {"extractionState": "manual", "localizations": {}}
    s[key]["localizations"]["zh-Hans"] = {"stringUnit": {"state": "translated", "value": zh}}
    s[key]["localizations"]["en"] = {"stringUnit": {"state": "translated", "value": en}}

# Performance Testing refactor
set_val("settings.developer.section.performance_test", "性能测试", "Performance Testing")
set_val("settings.developer.stressTest.run", "开始测试", "Run Test")
set_val("settings.developer.stressTest.count", "测试规模", "Test Scale")

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("✅ Successfully updated localization strings for Performance section.")
