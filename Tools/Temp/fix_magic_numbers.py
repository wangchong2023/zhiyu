import os
import re
import glob

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Define replacements
    replacements = [
        (r'\.font\(\.system\(size:\s*12,\s*weight:\s*\.bold\)\)', r'.font(.system(size: DesignSystem.captionFontSize, weight: .bold))'),
        (r'\.font\(\.system\(size:\s*10,\s*weight:\s*\.medium\)\)', r'.font(.system(size: DesignSystem.microFontSize, weight: .medium))'),
        (r'\.font\(\.system\(size:\s*24,\s*weight:\s*\.bold,\s*design:\s*\.rounded\)\)', r'.font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))'),
        (r'\.font\(\.system\(size:\s*48\)\)', r'.font(.system(size: DesignSystem.displayFontSize * 1.5))'),
        (r'\.font\(\.system\(size:\s*60\)\)', r'.font(.system(size: DesignSystem.Gallery.mainIconSize))'),
        (r'\.font\(\.system\(size:\s*8\)\)', r'.font(.system(size: DesignSystem.microFontSize))'),
        (r'\.font\(\.system\(size:\s*9\)\)', r'.font(.system(size: DesignSystem.microFontSize))'),
        (r'\.font\(\.system\(size:\s*14,\s*weight:\s*\.bold\)\)', r'.font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))'),
        (r'\.font\(\.system\(size:\s*32,\s*weight:\s*\.bold,\s*design:\s*\.rounded\)\)', r'.font(.system(size: DesignSystem.displayFontSize, weight: .bold, design: .rounded))'),
        (r'\.font\(\.system\(size:\s*14,\s*weight:\s*\.semibold\)\)', r'.font(.system(size: DesignSystem.subheadlineFontSize, weight: .semibold))'),
        (r'\.font\(\.system\(size:\s*40\)\)', r'.font(.system(size: DesignSystem.Gallery.iconSize))'),
        (r'\.font\(\.system\(size:\s*10,\s*design:\s*\.rounded\)\)', r'.font(.system(size: DesignSystem.microFontSize, design: .rounded))'),
        (r'\.font\(\.system\(size:\s*26,\s*weight:\s*\.bold,\s*design:\s*\.rounded\)\)', r'.font(.system(size: DesignSystem.titleFontSize + 2, weight: .bold, design: .rounded))'),
        (r'\.font\(\.system\(size:\s*10,\s*weight:\s*\.black\)\)', r'.font(.system(size: DesignSystem.microFontSize, weight: .black))'),
        (r'\.font\(\.system\(size:\s*11,\s*weight:\s*\.medium\)\)', r'.font(DesignSystem.caption2Font)'),
        (r'\.font\(\.system\(size:\s*14\)\)', r'.font(.system(size: DesignSystem.subheadlineFontSize))'),
        (r'\.font\(\.system\(size:\s*32\)\)', r'.font(.system(size: DesignSystem.displayFontSize))'),
        (r'\.font\(\.system\(size:\s*10\)\)', r'.font(.system(size: DesignSystem.microFontSize))'),
        (r'\.font\(\.system\(size:\s*11\)\)', r'.font(.system(size: DesignSystem.caption2FontSize))'),
        (r'\.font\(\.system\(size:\s*11,\s*weight:\s*\.semibold,\s*design:\s*\.rounded\)\)', r'.font(.system(size: DesignSystem.caption2FontSize, weight: .semibold, design: .rounded))'),
        (r'\.font\(\.system\(size:\s*9,\s*weight:\s*\.bold\)\)', r'.font(.system(size: DesignSystem.microFontSize, weight: .bold))'),
        (r'\.font\(\.system\(size:\s*DesignSystem\.caption2FontSize\s*\+\s*1,\s*weight:\s*\.medium\)\)', r'.font(.system(size: DesignSystem.captionFontSize, weight: .medium))'),
        (r'\.font\(\.system\(size:\s*DesignSystem\.caption2FontSize\s*\+\s*1\)\)', r'.font(.system(size: DesignSystem.captionFontSize))'),
    ]

    new_content = content
    for pattern, repl in replacements:
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('Sources/Features/'):
    for file in files:
        if file.endswith('.swift'):
            replace_in_file(os.path.join(root, file))
