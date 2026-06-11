import json

# 1. Add "search.filterTags" to Common.xcstrings
with open("Sources/Localization/Catalogs/Common.xcstrings", "r") as f:
    common_data = json.load(f)

common_data["strings"]["search.filterTags"] = {
    "extractionState": "manual",
    "localizations": {
        "en": {"stringUnit": {"state": "translated", "value": "Filter Tags"}},
        "zh-Hans": {"stringUnit": {"state": "translated", "value": "筛选标签"}}
    }
}
with open("Sources/Localization/Catalogs/Common.xcstrings", "w") as f:
    json.dump(common_data, f, indent=2, ensure_ascii=False)


# 2. Fix "title" in Plugin.xcstrings -> "plugin.title"
with open("Sources/Localization/Catalogs/Plugin.xcstrings", "r") as f:
    plugin_data = json.load(f)

if "title" in plugin_data.get("strings", {}):
    val = plugin_data["strings"].pop("title")
    plugin_data["strings"]["plugin.title"] = val
    with open("Sources/Localization/Catalogs/Plugin.xcstrings", "w") as f:
        json.dump(plugin_data, f, indent=2, ensure_ascii=False)
