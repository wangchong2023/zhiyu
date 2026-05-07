import json
import os

def update_localization():
    file_path = "/Users/constantine/Documents/work/code/projects/km/Sources/Localization/Localizable.xcstrings"
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    strings = data.get("strings", {})

    # New keys for Resource Monitoring
    new_keys = {
        "stats.navigationTitleMonitor": "资源监控",
        "stats.tabPerf": "性能与 AI",
        "stats.tabStorage": "存储与治理",
        "stats.provenance": "知识溯源统计",
        "stats.imported": "自动化入库页面",
        "stats.manuallyCreated": "手动创建页面",
        "stats.exportedRecent": "最近 30 天导出次数",
        "stats.cleanedPrefix": "已清理",
        "stats.cleanedSuffix": "个孤立数据块",
        "stats.aiResources": "AI 资源监控",
        "stats.storageDistribution": "存储分布",
        "stats.tokenTrend": "Token 消耗趋势",
        "stats.benchmark": "RAG 质量评估",
        "stats.storageAudit": "存储审计",
        "stats.perfAndQuality": "性能与质量",
        "stats.faithfulness": "忠实度",
        "stats.relevance": "关联度",
        "stats.precision": "准确度",
    }

    modified = False
    for key, value in new_keys.items():
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": value
                        }
                    }
                }
            }
            modified = True

    if modified:
        data["strings"] = strings
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("Updated Localizable.xcstrings with monitor keys.")
    else:
        print("No keys added.")

if __name__ == "__main__":
    update_localization()
