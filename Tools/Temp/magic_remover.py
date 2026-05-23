import os
import re

# Directory to scan
src_dir = 'Sources'

# Mappings
spacing_map = {
    "2": "DesignSystem.atomic",
    "4": "DesignSystem.tiny",
    "6": "DesignSystem.tightPadding",
    "8": "DesignSystem.small",
    "12": "DesignSystem.medium",
    "16": "DesignSystem.standardPadding",
    "20": "DesignSystem.wide",
    "24": "DesignSystem.giant",
    "32": "DesignSystem.huge",
}

radius_map = {
    "4": "DesignSystem.microRadius",
    "8": "DesignSystem.smallRadius",
    "10": "DesignSystem.mediumRadius",
    "12": "DesignSystem.standardRadius",
    "16": "DesignSystem.largeRadius",
    "20": "DesignSystem.chipRadius",
}

font_map = {
    "10": ".caption2",
    "12": ".caption",
    "13": ".footnote",
    "14": ".subheadline",
    "15": ".subheadline",
    "16": ".callout",
    "17": ".headline",
    "20": ".title3",
    "22": ".title2",
    "24": ".title",
    "28": ".title",
    "32": ".largeTitle",
    "34": ".largeTitle",
}

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. spacing: X -> spacing: DesignSystem.X
    def spacing_repl(match):
        num = match.group(1)
        return "spacing: " + spacing_map.get(num, num)
    
    content = re.sub(r'spacing:\s*(2|4|6|8|12|16|20|24|32)\b', spacing_repl, content)

    # 2. .padding(X) -> .padding(DesignSystem.X)
    def padding_repl(match):
        num = match.group(1)
        return ".padding(" + spacing_map.get(num, num) + ")"
        
    content = re.sub(r'\.padding\((2|4|6|8|12|16|20|24|32)\)', padding_repl, content)

    # 3. .padding(.top/.bottom/.leading/.trailing, X)
    def padding_edge_repl(match):
        edge = match.group(1)
        num = match.group(2)
        return f".padding({edge}, {spacing_map.get(num, num)})"
        
    content = re.sub(r'\.padding\((\.[a-zA-Z]+),\s*(2|4|6|8|12|16|20|24|32)\)', padding_edge_repl, content)
    
    # 4. .cornerRadius(X) -> .clipShape(RoundedRectangle(cornerRadius: DesignSystem.X))
    def radius_repl(match):
        num = match.group(1)
        if num in radius_map:
            return f".clipShape(RoundedRectangle(cornerRadius: {radius_map[num]}))"
        return match.group(0)
    
    content = re.sub(r'\.cornerRadius\((4|8|10|12|16|20)\)', radius_repl, content)

    # 5. .font(.system(size: X)) -> .font(Typography.XXX)
    def font_repl(match):
        num = match.group(1)
        if num in font_map:
            return f".font({font_map[num]})"
        return match.group(0)
        
    content = re.sub(r'\.font\(\.system\(size:\s*(10|12|13|14|15|16|17|20|22|24|28|32|34)\)\)', font_repl, content)

    # 6. .font(.system(size: X, weight: .XXX)) -> .font(Typography.XXX.weight(.XXX))
    def font_weight_repl(match):
        num = match.group(1)
        weight = match.group(2)
        if num in font_map:
            return f".font({font_map[num]}.weight({weight}))"
        return match.group(0)
        
    content = re.sub(r'\.font\(\.system\(size:\s*(10|12|13|14|15|16|17|20|22|24|28|32|34),\s*weight:\s*(\.[a-zA-Z]+)\)\)', font_weight_repl, content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(src_dir):
    # skip designsystem itself
    if "DesignSystem" in root:
        continue
    for file in files:
        if file.endswith('.swift'):
            replace_in_file(os.path.join(root, file))

print("Done")
