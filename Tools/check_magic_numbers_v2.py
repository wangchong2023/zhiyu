#!/usr/bin/env python3
"""精确扫描：排除 DesignSystem 定义文件和合法用法"""

import os, re

EXCLUDE_DIRS = {'.git','build','DerivedData','.build','Frameworks','Tests','env','__pycache__'}
# 定义设计令牌的文件本身不算魔鬼数字
TOKEN_FILES = {'Colors.swift','DesignSystem.swift','IconTokens.swift','Spacing.swift'}

# 只找真正的问题
results = []

for root, dirs, files in os.walk('Sources'):
    dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
    for fname in files:
        if not fname.endswith('.swift'): continue
        if fname in TOKEN_FILES: continue
        path = os.path.join(root, fname)
        
        with open(path, errors='ignore') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines, 1):
            s = line.strip()
            if s.startswith('//'): continue
            
            # 1. 颜色魔鬼数字：Color(red: 不带 DesignSystem
            if re.search(r'Color\(red:', line) and 'DesignSystem' not in line:
                results.append(('Color(red:)', path, i, s[:90]))
            
            # 2. 颜色魔鬼数字：Color(hex: 但 hex 是字面量字符串
            m = re.search(r'Color\(hex:\s*"([^"]+)"', line)
            if m:
                results.append(('Color(hex:"...")', path, i, s[:90]))
            
            # 3. 硬编码 padding/dimension 数值
            m = re.search(r'\.padding\(\s*(\d+)\s*\)', line)
            if m and 'DesignSystem' not in line:
                results.append(('hardcoded padding', path, i, s[:90]))
            
            # 4. 硬编码 cornerRadius 数值  
            m = re.search(r'cornerRadius:\s*(\d+)\s*[),]', line)
            if m and 'DesignSystem' not in line and 'Spacing' not in line:
                results.append(('hardcoded cornerRadius', path, i, s[:90]))

# 按文件分组
from collections import defaultdict
by_file = defaultdict(list)
for typ, path, line_no, code in results:
    rel = os.path.relpath(path)
    by_file[rel].append((typ, line_no, code))

print(f"🎯 实际需要修复的文件: {len(by_file)} 个\n")

# 只显示非 Widget、非测试的文件
priority_files = {}
for fpath, issues in sorted(by_file.items()):
    if 'Widget' in fpath or 'Widgets' in fpath:
        continue
    priority_files[fpath] = issues

print(f"高优先级文件（非 Widget）: {len(priority_files)} 个\n")
for fpath, issues in sorted(priority_files.items()):
    count = len(issues)
    print(f"  📄 {fpath} ({count} 处)")
    for typ, line_no, code in issues[:5]:
        print(f"     L{line_no}: [{typ}] {code}")
    if count > 5:
        print(f"     ... 还有 {count - 5} 处")
    print()

