import json

file_path = "/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Catalogs/System.xcstrings"
with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_keys = {
    "auth.litePlanTitle": "您当前是普通用户",
    "auth.proPlanTitle": "您当前是 Pro 用户",
    "auth.litePlanDesc": "基础配额，升级以解锁更多。目前仍可正常使用核心功能",
    "auth.proPlanDesc": "已解锁所有高级特性及专属权益",
    "auth.upgradeToPro": "升级到 PRO",
    "auth.unlockEverything": "解锁所有权限",
    "auth.unlimitedVaults": "无限金库数量",
    "auth.unlimitedPages": "无限知识页数量",
    "auth.aiSynthesis": "AI 深度综合与洞察分析",
    "auth.premiumPlugins": "100+ 高级扩展插件",
    "auth.prioritySupport": "高级优先技术支持",
    "auth.upgradeSuccessMsg": "您已成功升级为 Pro 用户！"
}

for k, v in new_keys.items():
    if k not in data["strings"]:
        data["strings"][k] = {
            "extractionState": "manual",
            "localizations": {
                "zh-Hans": {
                    "stringUnit": {
                        "state": "translated",
                        "value": v
                    }
                }
            }
        }

with open(file_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
