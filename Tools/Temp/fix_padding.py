import os
import re

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Define replacements for common padding numbers
    replacements = [
        (r'\.padding\(\.vertical,\s*4\)', r'.padding(.vertical, DesignSystem.tiny)'),
        (r'\.padding\(\.vertical,\s*6\)', r'.padding(.vertical, DesignSystem.small - 2)'),
        (r'\.padding\(\.vertical,\s*8\)', r'.padding(.vertical, DesignSystem.small)'),
        (r'\.padding\(\.vertical,\s*10\)', r'.padding(.vertical, DesignSystem.medium - 2)'),
        (r'\.padding\(\.vertical,\s*12\)', r'.padding(.vertical, DesignSystem.medium)'),
        (r'\.padding\(\.vertical,\s*40\)', r'.padding(.vertical, DesignSystem.large * 2.5)'),
        
        (r'\.padding\(\.horizontal,\s*4\)', r'.padding(.horizontal, DesignSystem.tiny)'),
        (r'\.padding\(\.horizontal,\s*8\)', r'.padding(.horizontal, DesignSystem.small)'),
        (r'\.padding\(\.horizontal,\s*10\)', r'.padding(.horizontal, DesignSystem.medium - 2)'),
        (r'\.padding\(\.horizontal,\s*12\)', r'.padding(.horizontal, DesignSystem.medium)'),
        (r'\.padding\(\.horizontal,\s*16\)', r'.padding(.horizontal, DesignSystem.standardPadding)'),
        
        (r'\.padding\(\.top,\s*4\)', r'.padding(.top, DesignSystem.tiny)'),
        (r'\.padding\(\.top,\s*10\)', r'.padding(.top, DesignSystem.medium - 2)'),
        
        (r'\.padding\(\.bottom,\s*30\)', r'.padding(.bottom, DesignSystem.large * 2)'),
        
        (r'\.padding\(8\)', r'.padding(DesignSystem.small)'),
        (r'\.padding\(12\)', r'.padding(DesignSystem.medium)'),
        (r'\.padding\(16\)', r'.padding(DesignSystem.standardPadding)'),
    ]

    new_content = content
    for pattern, repl in replacements:
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('Sources/Features/Settings/'):
    for file in files:
        if file.endswith('.swift'):
            replace_in_file(os.path.join(root, file))
