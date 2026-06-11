import json

with open("Sources/Localization/Catalogs/Plugin.xcstrings", "r", encoding="utf-8") as f:
    data = json.load(f)

if "title" in data["strings"]:
    data["strings"]["plugin.title"] = data["strings"]["title"]
    del data["strings"]["title"]
    with open("Sources/Localization/Catalogs/Plugin.xcstrings", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
