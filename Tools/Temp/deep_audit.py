import os
import re
from pathlib import Path

source_dir = Path("Sources")

large_files = []
grdb_in_domain = []
print_usage = []
os_macros = []
sf_symbols = []
user_defaults = []
missing_file_headers = []

domain_to_features = []
infra_to_features = []

for root, _, files in os.walk(source_dir):
    for file in files:
        if not file.endswith(".swift"):
            continue
        
        filepath = Path(root) / file
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        rel_path = filepath.relative_to(source_dir)
        path_str = str(rel_path)
        
        # File size
        if len(lines) > 300:
            large_files.append((path_str, len(lines)))
            
        # File header
        has_header = False
        for i, line in enumerate(lines[:10]):
            if "//" in line and any("\u4e00" <= c <= "\u9fa5" for c in line):
                has_header = True
                break
        if not has_header:
            missing_file_headers.append(path_str)
            
        for idx, line in enumerate(lines):
            line_num = idx + 1
            
            # Domain GRDB
            if path_str.startswith("Domain/") and re.search(r'import\s+GRDB', line):
                grdb_in_domain.append((path_str, line_num))
                
            # Cross layer
            if path_str.startswith("Domain/") and re.search(r'import\s+Features', line):
                domain_to_features.append((path_str, line_num))
            if path_str.startswith("Infrastructure/") and re.search(r'import\s+Features', line):
                infra_to_features.append((path_str, line_num))
                
            # print
            if re.search(r'\bprint\(', line):
                print_usage.append((path_str, line_num))
                
            # #if os
            if re.search(r'#if\s+os\(', line):
                os_macros.append((path_str, line_num))
                
            # SF Symbols
            if re.search(r'systemName:\s*".*"', line):
                sf_symbols.append((path_str, line_num))
                
            # UserDefaults
            if re.search(r'UserDefaults\.', line):
                user_defaults.append((path_str, line_num))

print("=== DEEP AUDIT RESULTS ===")
print(f"Large Files (>300 lines): {len(large_files)}")
for f, count in sorted(large_files, key=lambda x: x[1], reverse=True)[:10]:
    print(f"  {f}: {count} lines")

print(f"\nMissing Chinese File Headers: {len(missing_file_headers)}")
for f in missing_file_headers[:10]:
    print(f"  {f}")

print(f"\nDomain importing GRDB: {len(grdb_in_domain)}")
for f, l in grdb_in_domain:
    print(f"  {f}:{l}")

print(f"\nDomain importing Features: {len(domain_to_features)}")
print(f"Infra importing Features: {len(infra_to_features)}")

print(f"\nprint() usage: {len(print_usage)}")
print(f"#if os() macros: {len(os_macros)}")
print(f"SF Symbols (systemName): {len(sf_symbols)}")
print(f"UserDefaults usage: {len(user_defaults)}")

