import json

with open("Sources/Localization/Catalogs/Common.xcstrings", "r") as f:
    common_data = json.load(f)

common_data["strings"]["search.filterTags"]["localizations"]["zh-Hans"]["stringUnit"]["value"] = "筛选标签..."
common_data["strings"]["search.filterTags"]["localizations"]["en"]["stringUnit"]["value"] = "Filter tags..."

with open("Sources/Localization/Catalogs/Common.xcstrings", "w") as f:
    json.dump(common_data, f, indent=2, ensure_ascii=False)
