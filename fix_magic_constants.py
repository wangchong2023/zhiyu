import os
import re

design_system_path = "Sources/Shared/DesignSystem/DesignSystem.swift"
with open(design_system_path, "r", encoding="utf-8") as f:
    ds_content = f.read()

# Regexes
re_system_name = re.compile(r'Image\(systemName:\s*"([^"]+)"\)')
re_opacity = re.compile(r'\.opacity\(([0-9\.]+)\)')
re_frame = re.compile(r'\.frame\(width:\s*([0-9\.]+)(?:,\s*height:\s*([0-9\.]+))?\)')

icons_found = set()
opacities_found = set()
frames_found = set()

# Pass 1: Collect
for root, _, files in os.walk("Sources"):
    for file in files:
        if file.endswith(".swift") and file != "DesignSystem.swift":
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            icons_found.update(re_system_name.findall(content))
            opacities_found.update(re_opacity.findall(content))
            frames_found.update(re_frame.findall(content))

# Clean up found data
icons_dict = {}
for icon in sorted(icons_found):
    # Convert icon string to camelCase variable name
    parts = icon.replace('.fill', 'Fill').replace('.circle', 'Circle').replace('.square', 'Square').split('.')
    var_name = parts[0] + ''.join(p.capitalize() for p in parts[1:])
    var_name = var_name.replace('-', '')
    icons_dict[icon] = var_name

# Define Opacity map
opacity_map = {
    '0.04': 'atomic',
    '0.08': 'faint',
    '0.1': 'subtle',
    '0.12': 'light',
    '0.15': 'glass',
    '0.2': 'soft',
    '0.25': 'mediumLight',
    '0.3': 'shadow',
    '0.5': 'half',
    '0.6': 'dim',
    '0.8': 'heavy'
}

# Define Frame map
frame_map = {
    '6': 'atomic',
    '16': 'micro',
    '20': 'small',
    '24': 'standard',
    '28': 'medium',
    '32': 'large',
    '44': 'xlarge',
    '46': 'xxlarge',
    '48': 'huge'
}

# We need to manually update DesignSystem.swift
# Find the end of `public enum Icons {` and append the new icons
icon_insert_idx = ds_content.find("public enum Icons {")
if icon_insert_idx != -1:
    icon_end_idx = ds_content.find("\n    }", icon_insert_idx)
    existing_icons = ds_content[icon_insert_idx:icon_end_idx]
    
    new_icons_str = ""
    for icon, var_name in icons_dict.items():
        if f'"{icon}"' not in existing_icons:
            # Handle reserved keywords or duplicates manually if needed. Let's just prefix with icon if keyword
            if var_name in ["return", "class", "struct", "enum", "case", "for"]:
                var_name = "icon" + var_name.capitalize()
            new_icons_str += f'\n        public static let {var_name} = "{icon}"'
    ds_content = ds_content[:icon_end_idx] + new_icons_str + ds_content[icon_end_idx:]

# Add Opacity enum if not exists
if "public enum Opacity {" not in ds_content:
    opacity_enum = "\n    public enum Opacity {"
    for val, name in opacity_map.items():
        opacity_enum += f"\n        public static let {name}: Double = {val}"
    opacity_enum += "\n    }\n"
    ds_content += opacity_enum

# Add IconSize enum if not exists
if "public enum IconSize {" not in ds_content:
    iconsize_enum = "\n    public enum IconSize {"
    for val, name in frame_map.items():
        iconsize_enum += f"\n        public static let {name}: CGFloat = {val}"
    iconsize_enum += "\n    }\n"
    ds_content += iconsize_enum

with open(design_system_path, "w", encoding="utf-8") as f:
    f.write(ds_content)

# Pass 2: Replace
for root, _, files in os.walk("Sources"):
    for file in files:
        if file.endswith(".swift") and file != "DesignSystem.swift":
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            orig_content = content
            
            # Replace Icons
            for icon, var_name in icons_dict.items():
                content = content.replace(f'Image(systemName: "{icon}")', f'Image(systemName: DesignSystem.Icons.{var_name})')
            
            # Replace Opacity
            for val, name in opacity_map.items():
                content = content.replace(f'.opacity({val})', f'.opacity(DesignSystem.Opacity.{name})')
                
            # Replace Frames
            for val, name in frame_map.items():
                content = content.replace(f'.frame(width: {val}, height: {val})', f'.frame(width: DesignSystem.IconSize.{name}, height: DesignSystem.IconSize.{name})')
            
            if content != orig_content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)

print("Replacement complete.")
