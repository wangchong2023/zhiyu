import os
import re

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Define replacements for common frame numbers
    replacements = [
        (r'\.frame\(width:\s*8,\s*height:\s*8\)', r'.frame(width: DesignSystem.small, height: DesignSystem.small)'),
        (r'\.frame\(width:\s*100,\s*height:\s*100\)', r'.frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)'),
        (r'\.frame\(height:\s*180\)', r'.frame(height: DesignSystem.Metrics.chartHeight - 40)'),
        (r'\.frame\(width:\s*32,\s*height:\s*32\)', r'.frame(width: DesignSystem.Metrics.iconBoxSize - 8, height: DesignSystem.Metrics.iconBoxSize - 8)'),
        (r'\.frame\(height:\s*200\)', r'.frame(height: DesignSystem.Metrics.chartHeight - 20)'),
        (r'\.frame\(width:\s*24\)', r'.frame(width: DesignSystem.giant)'),
        (r'\.frame\(width:\s*6,\s*height:\s*6\)', r'.frame(width: DesignSystem.tiny + 2, height: DesignSystem.tiny + 2)'),
        (r'\.frame\(height:\s*160\)', r'.frame(height: DesignSystem.Metrics.chartHeight - 60)'),
        (r'\.frame\(width:\s*28,\s*height:\s*28\)', r'.frame(width: DesignSystem.smallIconSize + 12, height: DesignSystem.smallIconSize + 12)'),
        (r'\.frame\(height:\s*DesignSystem\.Metrics\.sourceCardHeight\s*\*\s*1\.22\)\s*//\s*140', r'.frame(height: DesignSystem.Metrics.sourceCardHeight * 1.22)'),
        (r'\.frame\(height:\s*240\)', r'.frame(height: DesignSystem.Metrics.chartHeight + 20)'),
        (r'\.frame\(maxWidth:\s*UIScreen\.main\.bounds\.width\s*\*\s*0\.45\)', r'.frame(maxWidth: .infinity)'), # Approximated, wait maybe keep it if it's dynamic
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
