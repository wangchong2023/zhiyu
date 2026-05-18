import os, re

replacements = {
    # Delete
    r'Ingest\.tr\("pdf\.delete"\)': r'Common.tr("misc.delete")',
    r'Knowledge\.tr\("tag\.delete"\)': r'Common.tr("misc.delete")',
    r'Common\.tr\("tagCloud\.delete"\)': r'Common.tr("misc.delete")',
    r'Common\.tr\("logAction\.delete"\)': r'Common.tr("misc.delete")',
    # OK
    r'Ingest\.tr\("ingest\.ok"\)': r'Common.tr("misc.ok")',
    r'Settings\.tr\("settings\.ok"\)': r'Common.tr("misc.ok")',
    r'Common\.tr\("misc\.confirm"\)': r'Common.tr("misc.ok")',
    # Settings
    r'Settings\.tr\("settings"\)': r'Common.tr("settings")',
    r'Settings\.tr\("settings\.settings"\)': r'Common.tr("settings")',
    r'Common\.tr\("misc\.settings"\)': r'Common.tr("settings")',
    # Health Check
    r'Lint\.tr\("title"\)': r'Common.tr("action.healthCheck")',
    r'Lint\.tr\("lint\.center\.title"\)': r'Common.tr("action.healthCheck")',
    r'Lint\.tr\("lint\.title"\)': r'Common.tr("action.healthCheck")',
    r'Settings\.tr\("settings\.healthCheck"\)': r'Common.tr("action.healthCheck")',
    r'Common\.tr\("logAction\.healthCheck"\)': r'Common.tr("action.healthCheck")',
    r'Common\.tr\("perf\.lint"\)': r'Common.tr("action.healthCheck")',
    r'Common\.tr\("perf\.summary\.lint"\)': r'Common.tr("action.healthCheck")'
}

ext_dir = "Sources/Localization/Extensions"
for f in os.listdir(ext_dir):
    if f.endswith(".swift"):
        path = os.path.join(ext_dir, f)
        with open(path, "r", encoding="utf-8") as file:
            content = file.read()
        
        original_content = content
        for old, new in replacements.items():
            content = re.sub(old, new, content)
        
        if content != original_content:
            with open(path, "w", encoding="utf-8") as file:
                file.write(content)
            print(f"Updated {f}")
