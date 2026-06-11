import os
import re

opacity_map = {
    '0.03': 'atomic',
    '0.04': 'faint',
    '0.05': 'ghost',
    '0.08': 'light',
    '0.1': 'subtle', 
    '0.12': 'subtle',
    '0.15': 'glass',
    '0.2': 'medium',
    '0.25': 'medium', 
    '0.3': 'shadow',
    '0.4': 'disabled',
    '0.5': 'soft',
    '0.6': 'dim',
    '0.7': 'overlay',
    '0.8': 'prominent',
    '1.0': 'solid'
}

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

re_opacity = re.compile(r'\.opacity\(([0-9\.]+)\)')
re_frame_square = re.compile(r'\.frame\(\s*width:\s*([0-9\.]+),\s*height:\s*\1')
re_frame_width = re.compile(r'\.frame\(\s*width:\s*([0-9\.]+)')
re_frame_height = re.compile(r'\.frame\(\s*height:\s*([0-9\.]+)')

for root, _, files in os.walk("Sources"):
    for file in files:
        if file.endswith(".swift"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            orig = content
            
            def op_repl(m):
                val = m.group(1)
                if val in opacity_map:
                    return f'.opacity(DesignSystem.Opacity.{opacity_map[val]})'
                return m.group(0)
            
            content = re_opacity.sub(op_repl, content)
            
            def frm_sq_repl(m):
                val = m.group(1)
                if val in frame_map:
                    return f'.frame(width: DesignSystem.IconSize.{frame_map[val]}, height: DesignSystem.IconSize.{frame_map[val]}'
                return m.group(0)
            
            content = re_frame_square.sub(frm_sq_repl, content)

            def frm_w_repl(m):
                val = m.group(1)
                if val in frame_map:
                    return f'.frame(width: DesignSystem.IconSize.{frame_map[val]}'
                return m.group(0)
                
            content = re_frame_width.sub(frm_w_repl, content)
            
            def frm_h_repl(m):
                val = m.group(1)
                if val in frame_map:
                    return f'.frame(height: DesignSystem.IconSize.{frame_map[val]}'
                return m.group(0)
                
            content = re_frame_height.sub(frm_h_repl, content)
            
            if content != orig:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)

print("Global cleanup completed.")
