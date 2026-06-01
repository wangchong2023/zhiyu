import json

file_path = "Sources/Localization/Catalogs/AI.xcstrings"
with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

data["strings"]["llm.prompt.default.slides"] = {
    "extractionState": "manual",
    "localizations": {
        "en": {
            "stringUnit": {
                "state": "translated",
                "value": "Default Slides"
            }
        },
        "zh-Hans": {
            "stringUnit": {
                "state": "translated",
                "value": "默认幻灯片"
            }
        }
    }
}
            
with open(file_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Fixed llm.prompt.default.slides")
