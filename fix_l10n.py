import json
import glob

# Fix stale extraction states
for f in glob.glob("Sources/Localization/Catalogs/*.xcstrings"):
    with open(f, "r") as file:
        data = json.load(file)
    
    modified = False
    for key, value in data.get("strings", {}).items():
        if value.get("extractionState") == "stale":
            value["extractionState"] = "manual"
            modified = True
            
    if modified:
        with open(f, "w") as file:
            json.dump(data, file, indent=2, ensure_ascii=False)
        print(f"Fixed extraction states in {f}")

# The audit complained about "title" key cross-file inconsistency.
# Plugin.xcstrings has "插件" but Common/Insight have "标签管理" / "Tags".
# We can just change "title" to "plugin.title" in Plugin.xcstrings and L10n+Plugin.swift
