#!/usr/bin/env python3
"""检查 @MainActor 访问安全：禁止直接使用 DispatchQueue.main.sync 和 MainActor.assumeIsolated。

runOnMainSync() 是唯一合法的跨线程 @MainActor 桥接入口。
"""

import sys, re, os

UNSAFE_PATTERNS = [
    (r'DispatchQueue\.main\.sync\b', 'DispatchQueue.main.sync — 使用 runOnMainSync 替代'),
    (r'MainActor\.assumeIsolated\b', 'MainActor.assumeIsolated — 使用 runOnMainSync 替代'),
]

ALLOWED_FILES = {
    'Core/Base/Utils/MainActorBridge.swift',  # 桥接函数本身的定义
    'Infrastructure/Plugins/JavaScriptPlugin.swift',  # loadData 已受 Thread.isMainThread 保护
}

issues = []
for root, dirs, files in os.walk('Sources'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.swift'): continue
        path = os.path.join(root, f)
        rel = os.path.relpath(path, os.getcwd())
        if any(rel.endswith(a) for a in ALLOWED_FILES): continue
        with open(path, 'r') as fh:
            lines = fh.readlines()
        for i, line in enumerate(lines, 1):
            for pattern, msg in UNSAFE_PATTERNS:
                if re.search(pattern, line) and 'runOnMainSync' not in line:
                    issues.append(f"{rel}:{i}: {msg}")

if issues:
    print(f"❌ 发现 {len(issues)} 处不安全的 @MainActor 访问：")
    for issue in issues: print(f"  {issue}")
    print("\n💡 请使用 Sources/Core/Base/Utils/MainActorBridge.swift 中的 runOnMainSync() 替代。")
    sys.exit(1)
else:
    print("✅ @MainActor 访问安全：所有跨线程桥接均通过 runOnMainSync")
    sys.exit(0)
