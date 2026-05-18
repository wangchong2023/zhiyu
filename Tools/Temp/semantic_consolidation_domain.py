import os, re

# 领域实体语义整合替换规则
replacements = {
    # Page Title
    r'Ingest\.tr\("ingest\.pageTitle"\)': r'Common.tr("pageTitle")',
    r'Ingest\.tr\("ocr\.pageTitle"\)': r'Common.tr("pageTitle")',
    r'Ingest\.tr\("pdf\.pageTitle"\)': r'Common.tr("pageTitle")',
    r'Creation\.tr\("pageTitle"\)': r'Common.tr("pageTitle")',
    r'Knowledge\.tr\("page\.title"\)': r'Common.tr("pageTitle")',
    r'AI\.tr\("llm\.prompt\.pageTitle"\)': r'Common.tr("pageTitle")',
    r'Common\.tr\("create\.page\.title"\)': r'Common.tr("pageTitle")',
    r'Common\.tr\("create\.pageTitle"\)': r'Common.tr("pageTitle")',
    # Sources
    r'Ingest\.tr\("sources"\)': r'Common.tr("sources")',
    r'Dashboard\.tr\("dashboard\.index\.sources"\)': r'Common.tr("sources")',
    r'Dashboard\.tr\("dashboard\.pageList\.sources"\)': r'Common.tr("sources")',
    r'Dashboard\.tr\("dashboard\.stats\.typeSource"\)': r'Common.tr("sources")',
    r'Common\.tr\("pageList\.sources"\)': r'Common.tr("sources")',
    r'Common\.tr\("type\.source"\)': r'Common.tr("sources")'
}

ext_dir = "Sources/Localization/Extensions"

if not os.path.exists(ext_dir):
    print(f"Error: {ext_dir} not found.")
    exit(1)

for root, dirs, files in os.walk(ext_dir):
    for f in files:
        if f.endswith(".swift"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            
            original_content = content
            for old, new in replacements.items():
                content = re.sub(old, new, content)
            
            if content != original_content:
                with open(path, "w", encoding="utf-8") as file:
                    file.write(content)
                print(f"Updated: {path}")

print("Domain semantic consolidation completed.")
