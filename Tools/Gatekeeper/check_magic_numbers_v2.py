#!/usr/bin/env python3
"""精确扫描：排除 DesignSystem 定义文件和合法用法"""

import os, re, sys

EXCLUDE_DIRS = {'.git','build','DerivedData','.build','Frameworks','Tests','env','__pycache__'}
TOKEN_FILES = {'Colors.swift','DesignSystem.swift','IconTokens.swift','Spacing.swift'}
TOKEN_FILES_PY = {'mock_constants.py'}

SWIFT_EXT = {'.swift'}
PY_EXT = {'.py'}

def scan_file(path, ext):
    issues = []
    with open(path, errors='ignore') as f:
        lines = f.readlines()
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith('//') or s.startswith('#'):
            continue
        if ext in SWIFT_EXT:
            issues.extend(check_swift_line(path, i, s, line))
        if ext in PY_EXT:
            issues.extend(check_python_line(path, i, s, line))
    return issues


def check_swift_line(path, line_no, s, raw):
    results = []
    if re.search(r'Color\(red:', raw) and 'DesignSystem' not in raw:
        results.append(('Color(red:)', path, line_no, s[:90]))
    m = re.search(r'Color\(hex:\s*"([^"]+)"', raw)
    if m:
        results.append(('Color(hex:"...")', path, line_no, s[:90]))
    m = re.search(r'\.padding\(\s*(\d+)\s*\)', raw)
    if m and 'DesignSystem' not in raw:
        results.append(('hardcoded padding', path, line_no, s[:90]))
    m = re.search(r'cornerRadius:\s*(\d+)\s*[),]', raw)
    if m and 'DesignSystem' not in raw and 'Spacing' not in raw:
        results.append(('hardcoded cornerRadius', path, line_no, s[:90]))
    return results


def check_python_line(path, line_no, s, raw):
    results = []
    if 'mock_constants' in path:
        return results
    if re.search(r'port\s*=\s*\d{4,5}\b', raw) and 'PORT' not in raw:
        results.append(('硬编码端口号', path, line_no, s[:90]))
    if re.match(r'^[A-Z][A-Z_]*\s*=', s):
        return results
    m = re.search(r'["\'](\d+\.\d+\.\d+)["\']', raw)
    if m and m.group(1) not in ('',):
        if 'version' in raw.lower():
            if 'version=' not in raw:
                results.append(('硬编码版本号', path, line_no, s[:90]))
    return results


results = []
scan_dirs = ['Sources', 'Tools/Mock']

for scan_dir in scan_dirs:
    if not os.path.isdir(scan_dir):
        continue
    for root, dirs, files in os.walk(scan_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for fname in files:
            ext = os.path.splitext(fname)[1]
            scanner_exts = {'.swift': '.swift', '.py': '.py'}
            if ext not in scanner_exts:
                continue
            if fname in TOKEN_FILES or fname in TOKEN_FILES_PY:
                continue
            path = os.path.join(root, fname)
            results.extend(scan_file(path, ext))

from collections import defaultdict
by_file = defaultdict(list)
for typ, path, line_no, code in results:
    rel = os.path.relpath(path)
    by_file[rel].append((typ, line_no, code))

print(f"实际需要修复的文件: {len(by_file)} 个\n")

priority_files = {}
for fpath, issues in sorted(by_file.items()):
    if 'Widget' in fpath or 'Widgets' in fpath:
        continue
    priority_files[fpath] = issues

print(f"高优先级文件（非 Widget）: {len(priority_files)} 个\n")
for fpath, issues in sorted(priority_files.items()):
    count = len(issues)
    print(f"  {fpath} ({count} 处)")
    for typ, line_no, code in issues[:5]:
        print(f"     L{line_no}: [{typ}] {code}")
    if count > 5:
        print(f"     ... 还有 {count - 5} 处")
    print()

if priority_files:
    print(f"❌ 发现 {len(priority_files)} 个文件包含魔鬼数字，请替换为 DesignSystem token。")
    sys.exit(1)
else:
    print("✅ 未发现魔鬼数字/字符串。")
