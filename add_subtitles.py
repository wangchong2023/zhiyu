import json

with open("Sources/Localization/Catalogs/Insight.xcstrings", "r") as f:
    data = json.load(f)

new_keys = {
    "dashboard.stats.rankingQuality": {"en": "Ranking Quality", "zh-Hans": "排序质量"},
    "dashboard.stats.coverage": {"en": "Coverage", "zh-Hans": "召回覆盖"},
    "dashboard.stats.contextFidelity": {"en": "Context Fidelity", "zh-Hans": "上下文保真度"},
    "dashboard.stats.responseLatency": {"en": "Response Latency", "zh-Hans": "响应时延"}
}

for key, values in new_keys.items():
    data["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": values["en"]}},
            "zh-Hans": {"stringUnit": {"state": "translated", "value": values["zh-Hans"]}}
        }
    }

with open("Sources/Localization/Catalogs/Insight.xcstrings", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
