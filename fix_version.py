import json
import os

base_path = "Sources/Localization/Catalogs"
for file in os.listdir(base_path):
    if file.endswith('.xcstrings'):
        file_path = os.path.join(base_path, file)
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            
        if "version" not in data:
            data["version"] = "1.0"
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                f.write("\n")
            print(f"Added version to {file}")
