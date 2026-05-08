import json
import os

file_path = '/Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Localization/Localizable.xcstrings'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Fix page.backlinkAccessibility
# It was "%d pages", but used with (title, type)
if "page.backlinkAccessibility" in data["strings"]:
    data["strings"]["page.backlinkAccessibility"]["localizations"]["en"]["stringUnit"]["value"] = "Linked page: %@, Type: %@"
    data["strings"]["page.backlinkAccessibility"]["localizations"]["zh-Hans"]["stringUnit"]["value"] = "反向链接页面：%@，类型：%@"
    print("Fixed page.backlinkAccessibility")

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
