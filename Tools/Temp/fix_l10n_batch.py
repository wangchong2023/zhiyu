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

# Fix existing mismatches
set_val("page.deletePageTitle", "删除页面：\"%@\"", "Delete page: \"%@\"")
set_val("page.metaAccessibility", "创建于：%1$@，字数：%2$d，外链：%3$d", "Created: %1$@, Words: %2$d, Links: %3$d")
set_val("widget.pages", "%d 页面", "%d Pages")

# Add missing keys
set_val("injectDemo.successMessage", "已成功注入 %d 条示例数据", "Successfully injected %d demo entries")
set_val("developer.stressTest.success", "压力测试完成，生成了 %d 个页面", "Stress test completed, generated %d pages")
set_val("developer.stressTest.confirmAction", "确认生成 %d 个压力测试页面？", "Confirm generating %d stress test pages?")
set_val("nodesConnections", "%1$d 个节点, %2$d 条连接", "%1$d nodes, %2$d connections")
set_val("history.count", "历史记录 (%d)", "History (%d)")
set_val("linksCountFormat", "%d 条链接", "%d links")
set_val("graph.cluster.name", "聚类群组 %d", "Cluster group %d")

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("✅ Successfully updated localization strings.")
