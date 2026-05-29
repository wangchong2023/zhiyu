import os
import re

dirs = ["Sources/Features", "Sources/Shared", "Sources/Platforms", "Sources/App/Views"]

patterns = [
    (re.compile(r'@Environment\(AppStore\.self\)'), r'@Environment(\.appStore)'),
    (re.compile(r'@Environment\(Router\.self\)'), r'@Environment(\.router)'),
    (re.compile(r'@Inject var store: AppStore'), r'@Inject var store: any AppStoreProtocol'),
    (re.compile(r'@Inject var router: Router'), r'@Inject var router: any RouterProtocol'),
    # Handle parameter types in init or functions
    (re.compile(r': AppStore\b'), r': any AppStoreProtocol'),
    (re.compile(r': Router\b'), r': any RouterProtocol'),
    # Fix nested type prefixes
    (re.compile(r'AppStore\.CoachMarkType'), r'CoachMarkType'),
    (re.compile(r'AppStore\.KnowledgeGrowthPoint'), r'KnowledgeGrowthPoint'),
    (re.compile(r'AppStore\.ToolItem'), r'ToolItem'),
]

for d in dirs:
    if not os.path.exists(d): continue
    for root, _, files in os.walk(d):
        for f in files:
            if not f.endswith(".swift"): continue
            path = os.path.join(root, f)
            
            # Skip files I already manually updated or shouldn't touch
            if "AppStore.swift" in f or "Router.swift" in f:
                continue
                
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            
            new_content = content
            for p, r in patterns:
                new_content = p.sub(r, new_content)
            
            if new_content != content:
                with open(path, "w", encoding="utf-8") as file:
                    file.write(new_content)
                print(f"Updated {path}")
