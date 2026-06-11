import json

file_path = "Sources/Localization/Catalogs/System.xcstrings"
with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

new_keys = {
    "auth.save20Percent": {"en": "Save 20%", "zh-Hans": "省 20%"},
    "auth.priceMonthlyPro": {"en": "$14.99 / mo", "zh-Hans": "¥38 / 月"},
    "auth.priceYearlyPro": {"en": "$149.99 / yr", "zh-Hans": "¥368 / 年"},
    "auth.priceMonthlyLite": {"en": "$0 / mo", "zh-Hans": "¥0 / 月"},
    "auth.priceMonthlyProEquivalent": {"en": "$12.49 / mo", "zh-Hans": "¥30.6 / 月"},
    "auth.upgradeToProYearly": {"en": "Upgrade to Pro for $149.99 / year", "zh-Hans": "升级到专业版 - ¥368 / 年"},
    "auth.upgradeToProMonthly": {"en": "Upgrade to Pro for $14.99 / month", "zh-Hans": "升级到专业版 - ¥38 / 月"}
}

for key, trans in new_keys.items():
    data["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": trans["en"]
                }
            },
            "zh-Hans": {
                "stringUnit": {
                    "state": "translated",
                    "value": trans["zh-Hans"]
                }
            }
        }
    }

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
