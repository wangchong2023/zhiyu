import os
import re
from pathlib import Path
from collections import defaultdict

source_dir = Path("Sources")

report = []
report.append("# ZhiYu 代码质量与架构深度审计报告")
report.append("> **审计日期**: 2026-05-29\n")

# Stats
total_files = 0
total_lines = 0

large_files = []
large_funcs = []
missing_headers = []
magic_numbers = []
sf_symbols = []
user_defaults = []
os_macros = []
print_usage = []

# Architecture
domain_deps = []
infra_deps = []
app_store_refs = []
router_refs = []
shared_deps = []

for root, _, files in os.walk(source_dir):
    for file in files:
        if not file.endswith(".swift"):
            continue
        
        filepath = Path(root) / file
        total_files += 1
        
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        total_lines += len(lines)
        rel_path = filepath.relative_to(source_dir)
        path_str = str(rel_path)
        
        # File Size
        if len(lines) > 300:
            large_files.append((path_str, len(lines)))
            
        # File Header Comments
        has_header = any("//" in line and any("\u4e00" <= c <= "\u9fa5" for c in line) for line in lines[:10])
        if not has_header:
            missing_headers.append(path_str)
            
        for idx, line in enumerate(lines):
            line_num = idx + 1
            
            # Print
            if re.search(r'\bprint\(', line):
                print_usage.append((path_str, line_num, line.strip()))
                
            # OS Macros
            if re.search(r'#if\s+os\(', line):
                os_macros.append((path_str, line_num))
                
            # SF Symbols
            if re.search(r'systemName:\s*".*"', line):
                sf_symbols.append((path_str, line_num, line.strip()))
                
            # UserDefaults string keys
            if re.search(r'UserDefaults\.(standard|shared)\.(set|string|integer|bool)\(.*".*"\)', line):
                user_defaults.append((path_str, line_num, line.strip()))
                
            # AppStore / Router usage
            if "AppStore" in line and not path_str.startswith("App/") and not path_str.startswith("Core/Base/"):
                app_store_refs.append((path_str, line_num))
            if "Router" in line and not path_str.startswith("App/") and not path_str.startswith("Core/Base/"):
                router_refs.append((path_str, line_num))
                
            # Architecture Violations
            if path_str.startswith("Domain/"):
                if re.search(r'import\s+(UIKit|AppKit|SwiftUI)', line):
                    domain_deps.append((path_str, line_num, "Import UI framework"))
                if re.search(r'import\s+GRDB', line):
                    domain_deps.append((path_str, line_num, "Import GRDB"))
            
            if path_str.startswith("Infrastructure/"):
                if re.search(r'import\s+(UIKit|AppKit|SwiftUI)', line):
                    infra_deps.append((path_str, line_num, "Import UI framework"))
            
            if path_str.startswith("Shared/"):
                if re.search(r'import\s+(Domain|Infrastructure|Features)', line):
                    shared_deps.append((path_str, line_num, "Import Upper Layer"))

report.append(f"**代码规模**: {total_files} 文件 / {total_lines} 行 Swift 源码\n")

report.append("## 一、模块与文件划分 (SRP & File Size)")
report.append(f"发现 **{len(large_files)}** 个大文件(>300行)。超大文件通常违反单一职责原则(SRP)，建议拆分。")
report.append("| 文件路径 | 行数 |")
report.append("| :--- | :---: |")
for f, count in sorted(large_files, key=lambda x: x[1], reverse=True)[:15]:
    report.append(f"| `{f}` | {count} |")
report.append("\n")

report.append("## 二、架构合规性与层级解耦 (Architecture & SOLID)")
report.append("### 1. Domain 层纯净化 (L1.5)")
if domain_deps:
    for f, l, msg in domain_deps:
        report.append(f"- 🔴 `{f}:{l}`: {msg}")
else:
    report.append("- ✅ Domain 层未发现 UI 或数据库框架硬依赖。")

report.append("\n### 2. 上帝对象引用 (AppStore / Router)")
report.append(f"发现 **{len(app_store_refs)}** 处跨层直接引用 `AppStore`，**{len(router_refs)}** 处引用 `Router`。")
if app_store_refs:
    report.append("前 5 处 AppStore 跨层调用：")
    for f, l in app_store_refs[:5]:
        report.append(f"- `{f}:{l}`")

report.append("\n### 3. Shared 层越界依赖")
if shared_deps:
    for f, l, msg in shared_deps:
        report.append(f"- 🔴 `{f}:{l}`: {msg}")
else:
    report.append("- ✅ Shared 层未直接 import 业务层。")

report.append("\n## 三、多端适配层与宏治理 (#if os)")
report.append(f"全工程仍散落 **{len(os_macros)}** 处 `#if os()` 宏。理想状态下业务层不应包含平台宏，应通过注入或 Coordinator 屏蔽差异。")
macro_counts = defaultdict(int)
for f, _ in os_macros:
    macro_counts[f] += 1
report.append("| 包含平台宏的文件 | 数量 |")
report.append("| :--- | :---: |")
for f, count in sorted(macro_counts.items(), key=lambda x: x[1], reverse=True)[:10]:
    report.append(f"| `{f}` | {count} |")

report.append("\n## 四、中文注释覆盖率 (Documentation)")
report.append(f"发现 **{len(missing_headers)}** 个文件缺失中文文件头注释。")
for f in missing_headers:
    report.append(f"- `{f}`")

report.append("\n## 五、清理与坏味道 (Clean Code)")
report.append(f"### 1. 魔法字符串与硬编码")
report.append(f"- **SF Symbols**: 发现 {len(sf_symbols)} 处直接使用 `systemName:`。")
for f, l, code in sf_symbols[:5]:
    report.append(f"  - `{f}:{l}` -> `{code}`")
report.append(f"- **UserDefaults Magic Keys**: 发现 {len(user_defaults)} 处硬编码。")
for f, l, code in user_defaults[:5]:
    report.append(f"  - `{f}:{l}` -> `{code}`")

report.append(f"\n### 2. 调试残留")
report.append(f"- 发现 **{len(print_usage)}** 处 `print()` 调用，应替换为标准日志库(Logger)。")

report.append("\n## 六、总结与重构建议")
report.append("""
1. **清理废弃代码**：移除所有的 `print` 和多余的测试残留。
2. **消灭上帝对象**：当前 Features 对 `AppStore` 和 `Router` 存在大量跨层引用，建议在 Core 层声明 `AppStoreProtocol` 以解耦。
3. **治理大文件**：拆分 `DesignSystem.swift` 和 600行以上的 `View` 或 `Manager`。
4. **消除宏和魔法字符串**：将 `systemName` 收敛至 `DesignSystem`，`UserDefaults` 收敛至专用 Storage 组件。
""")

report_str = "\n".join(report)
with open("Docs/Testing/CODE_QUALITY_AUDIT_2026_05_29.md", "w", encoding="utf-8") as f:
    f.write(report_str)
print("Report generated to Docs/Testing/CODE_QUALITY_AUDIT_2026_05_29.md")
