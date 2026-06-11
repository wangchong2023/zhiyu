import json

with open("Sources/Localization/Catalogs/Insight.xcstrings", "r", encoding="utf-8") as f:
    data = json.load(f)

def add_string(key, en_val, zh_val):
    data["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": en_val}},
            "zh-Hans": {"stringUnit": {"state": "translated", "value": zh_val}}
        }
    }

add_string("dashboard.stats.rankingQuality", "Ranking Quality", "排序质量")
add_string("dashboard.stats.coverage", "Coverage", "覆盖率")
add_string("dashboard.stats.contextFidelity", "Context Fidelity", "上下文保真度")
add_string("dashboard.stats.responseLatency", "Response Latency", "响应延迟")

add_string("dashboard.stats.tab.retrieval", "Retrieval", "检索阶段")
add_string("dashboard.stats.tab.generation", "Generation", "生成阶段")
add_string("dashboard.stats.tab.satisfaction", "Feedback", "满意度及消耗")
add_string("dashboard.stats.tab.history", "History", "评估记录")

with open("Sources/Localization/Catalogs/Insight.xcstrings", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
