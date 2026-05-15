
import json
import os

def update_catalog(file_path, new_keys):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'strings' not in data:
        data['strings'] = {}
        
    for key, values in new_keys.items():
        data['strings'][key] = {
            "extractionState": "manual",
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": values['en']
                    }
                },
                "zh-Hans": {
                    "stringUnit": {
                        "state": "translated",
                        "value": values['zh']
                    }
                }
            }
        }
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Updated {file_path}")

# Settings Keys
settings_keys = {
    "about.developer": {"en": "Developer", "zh": "开发者"},
    "about.website": {"en": "Website", "zh": "官方网站"},
    "about.license": {"en": "Open Source", "zh": "开源协议"},
    "injectDemo.errorMessage": {"en": "Injection failed, check database", "zh": "注入失败，请检查数据库状态"}
}
update_catalog("Sources/Localization/Settings.xcstrings", settings_keys)

# Dashboard Keys
dashboard_keys = {
    "stats.latencyTitle": {"en": "Response Latency", "zh": "响应时延"},
    "stats.avgLatencyShort": {"en": "Avg", "zh": "平均"},
    "stats.maxLatency": {"en": "Max", "zh": "最大"},
    "stats.minLatency": {"en": "Min", "zh": "最小"},
    "stats.measureCount": {"en": "Samples", "zh": "测量次数"}
}
update_catalog("Sources/Localization/Dashboard.xcstrings", dashboard_keys)
