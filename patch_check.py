import os
import re

file_path = "Tools/check_localization.py"

with open(file_path, "r") as f:
    content = f.read()

injection = """
def check_missing_keys():
    import json
    xcstrings_keys = set()
    catalogs_dir = 'Sources/Localization/Catalogs'
    for file in os.listdir(catalogs_dir):
        if file.endswith('.xcstrings'):
            with open(os.path.join(catalogs_dir, file), 'r', encoding='utf-8') as f:
                data = json.load(f)
                strings = data.get('strings', {})
                for key in strings.keys():
                    xcstrings_keys.add(key)
                    
    tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
    tr_func_pattern = re.compile(r'trf?\(\s*"([^"]+)"')
    
    extensions_dir = 'Sources/Localization/Extensions'
    missing = []
    
    for file in os.listdir(extensions_dir):
        if file.endswith('.swift'):
            path = os.path.join(extensions_dir, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                matches1 = tr_pattern.findall(content)
                matches2 = tr_func_pattern.findall(content)
                
                for key in set(matches1 + matches2):
                    if key not in xcstrings_keys:
                        missing.append((path, key, "Key defined in L10n extension but missing in .xcstrings", "ERROR"))
    return missing
"""

content = content.replace("def main():", injection + "\ndef main():")

main_replacement = """    xcstrings_issues = audit_xcstrings()
    
    # Check for missing keys
    missing_key_issues = check_missing_keys()
    
    has_critical = False
"""

content = content.replace("    xcstrings_issues = audit_xcstrings()\n    \n    has_critical = False", main_replacement)

print_replacement = """    if xcstrings_issues:
        print("\\n❌ [L10n Audit] .xcstrings Catalog Issues:")
        current_file = ""
        for file, key, msg, level in xcstrings_issues:
            if file != current_file:
                print(f"\\n📂 {file}")
                current_file = file
            icon = "🚨" if level == "ERROR" or level == "CRITICAL" else "⚠️"
            if level == "ERROR" or level == "CRITICAL": has_critical = True
            print(f"  Key: \\"{key}\\" - {icon} [{level}] {msg}")

    if missing_key_issues:
        print("\\n❌ [L10n Audit] Missing Keys in Catalogs:")
        for file, key, msg, level in missing_key_issues:
            icon = "🚨"
            has_critical = True
            print(f"  📂 {file}")
            print(f"  Key: \\"{key}\\" - {icon} [{level}] {msg}")
            
    if not all_source_issues and not xcstrings_issues and not missing_key_issues:"""

content = content.replace("""    if xcstrings_issues:
        print("\\n❌ [L10n Audit] .xcstrings Catalog Issues:")
        current_file = ""
        for file, key, msg, level in xcstrings_issues:
            if file != current_file:
                print(f"\\n📂 {file}")
                current_file = file
            icon = "🚨" if level == "ERROR" or level == "CRITICAL" else "⚠️"
            if level == "ERROR" or level == "CRITICAL": has_critical = True
            print(f"  Key: \\"{key}\\" - {icon} [{level}] {msg}")

    if not all_source_issues and not xcstrings_issues:""", print_replacement)

with open(file_path, "w") as f:
    f.write(content)

print("Patched check_localization.py")
