#!/usr/bin/env python3
"""扫描 Swift 源码中的魔鬼数字（硬编码的颜色、尺寸、数值）"""

import os, re, sys

EXCLUDE_DIRS = {'.git', 'build', 'DerivedData', '.build', 'Frameworks', 'Tests', 'env', '__pycache__'}

# 魔鬼数字模式
PATTERNS = {
    # 颜色恶魔数字
    'Color(red:':       re.compile(r'Color\(\s*red\s*:\s*[\d.]+'),
    'Color(uiColor:':   re.compile(r'Color\(\s*uiColor\s*:'),
    'UIColor(red:':     re.compile(r'UIColor\(\s*red\s*:'),
    'UIColor(hex:':     re.compile(r'UIColor\(\s*hex\s*:'),
    'Color(hex:':       re.compile(r'Color\(\s*hex\s*:'),
    # 数值魔鬼数字
    'hardcoded_opacity': re.compile(r'opacity\(\s*(0\.[0-9]+|1\.0|1)\)'), # 非 DesignSystem 的 opacity
    'hardcoded_radius':  re.compile(r'cornerRadius:|clipShape.*radius:\s*(\d+)'),
    'hardcoded_padding': re.compile(r'\.padding\(\s*(\d+)\)'),
    'hardcoded_frame':   re.compile(r'\.frame\(\s*(width|height)\s*:\s*[\d.]+'),
    # 其他常见魔鬼数字
    'timeout':  re.compile(r'timeoutInterval\s*:\s*\d+'),
    'delay':    re.compile(r'\.sleep\(\s*[\d.]+\s*\)'),
    'debounce': re.compile(r'debounce.*:.*[\d.]+'),
    'font_size': re.compile(r'font:.*size:\s*\d+'),
}

results = {k: [] for k in PATTERNS}

for root, dirs, files in os.walk('Sources'):
    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
    for f in files:
        if not f.endswith('.swift'): continue
        path = os.path.join(root, f)
        with open(path, errors='ignore') as fp:
            for i, line in enumerate(fp, 1):
                line_stripped = line.strip()
                if line_stripped.startswith('//'): continue
                for name, pat in PATTERNS.items():
                    if pat.search(line):
                        results[name].append((path, i, line_stripped[:100]))

# 输出报告
total = sum(len(v) for v in results.values())
print(f"🔍 魔鬼数字扫描结果: {total} 处\n")

for name, findings in sorted(results.items()):
    if not findings: continue
    print(f"\n{'='*70}")
    print(f"  {name}: {len(findings)} 处")
    print(f"{'='*70}")
    for path, line_no, code in findings[:8]:  # 最多显示 8 个
        short = os.path.relpath(path)
        print(f"  📄 {short}:{line_no}")
        print(f"     {code}")
    if len(findings) > 8:
        print(f"     ... 还有 {len(findings) - 8} 处")

print(f"\n{'='*70}")
print(f"总计: {total} 处魔鬼数字")

# 检查是否在 DesignSystem/Constants 中
if total:
    print("\n建议:")
    print("  • 颜色 → 使用 DesignSystem/Colors.swift 中定义的设计令牌")
    print("  • 尺寸 → 使用 DesignSystem 中定义的常量 (medium, small 等)")
    print("  • 数值 → 提取为有意义的命名常量")
