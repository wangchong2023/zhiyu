import os
import re

src_dir = 'Sources'

def size_to_semantic(size):
    size = int(size)
    if size <= 10: return ".caption2"
    if size <= 12: return ".caption"
    if size == 13: return ".footnote"
    if size <= 15: return ".subheadline"
    if size == 16: return ".callout"
    if size == 17: return ".headline" # or body
    if size <= 20: return ".title3"
    if size <= 22: return ".title2"
    if size <= 28: return ".title"
    return ".largeTitle"

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content

    # Helper for `.font(.system(size: X))`
    # and `.font(.system(size: X, weight: .Y))`
    # and `.font(.system(size: X, design: .Z))`
    # and `.font(.system(size: X, weight: .Y, design: .Z))`
    
    # 1. size, weight, design
    def repl_all(match):
        size = match.group(1)
        weight = match.group(2)
        design = match.group(3)
        semantic = size_to_semantic(size)
        return f".font({semantic}.weight({weight}))" if weight else f".font({semantic})"
        
    content = re.sub(r'\.font\(\.system\(size:\s*(\d+),\s*weight:\s*(\.[a-zA-Z]+),\s*design:\s*(\.[a-zA-Z]+)\)\)', 
                     lambda m: f".font({size_to_semantic(m.group(1))}.weight({m.group(2)}))", content)

    # 2. size, weight
    content = re.sub(r'\.font\(\.system\(size:\s*(\d+),\s*weight:\s*(\.[a-zA-Z]+)\)\)', 
                     lambda m: f".font({size_to_semantic(m.group(1))}.weight({m.group(2)}))", content)

    # 3. size, design
    content = re.sub(r'\.font\(\.system\(size:\s*(\d+),\s*design:\s*(\.[a-zA-Z]+)\)\)', 
                     lambda m: f".font({size_to_semantic(m.group(1))})", content)

    # 4. size only
    content = re.sub(r'\.font\(\.system\(size:\s*(\d+)\)\)', 
                     lambda m: f".font({size_to_semantic(m.group(1))})", content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(src_dir):
    if "DesignSystem" in root or "Platforms" in root:
        continue
    for file in files:
        if file.endswith('.swift'):
            replace_in_file(os.path.join(root, file))

print("Done")
