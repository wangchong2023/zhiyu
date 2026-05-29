import re
import os

dirs = ["Sources/Features", "Sources/Shared", "Sources/Platforms", "Sources/App/Views", "Sources/App"]

macro_pattern = re.compile(r'#if os\(iOS\)\s*\n\s*\.navigationBarTitleDisplayMode\((.*?)\)\s*\n\s*#endif')

for d in dirs:
    if not os.path.exists(d): continue
    for root, _, files in os.walk(d):
        for f in files:
            if not f.endswith(".swift"): continue
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            
            # replace block with .appNavigationBarTitleDisplayMode(...)
            new_content = macro_pattern.sub(r'.appNavigationBarTitleDisplayMode(\1)', content)
            
            if new_content != content:
                with open(path, "w", encoding="utf-8") as file:
                    file.write(new_content)
                print(f"Updated {path}")
