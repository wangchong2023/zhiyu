#!/usr/bin/env python3
"""
check_missing_l10n.py
全工程本地化缺失键扫描工具
扫描所有 Swift 文件中通过 L10n.*.tr() / Localized.tr() 调用的键，
与各 .xcstrings 文件中实际定义的键进行交叉比对，输出缺失清单。
"""

import os
import re
import json
import sys
from pathlib import Path

# ──────────────────────────────────────────
# 配置
# ──────────────────────────────────────────
PROJECT_ROOT = Path("/Users/constantine/Documents/work/code/projects/ZhiYu")
SOURCES_DIR  = PROJECT_ROOT / "Sources"
L10N_DIR     = SOURCES_DIR / "Localization"

# L10n 结构体前缀 → (xcstrings 文件名, 键前缀)
# 从 Localized.swift 中整理而来
L10N_TABLE_MAP = {
    "L10n.Graph.tr":        ("Graph",         "graph."),
    "L10n.Graph.ThreeD.tr": ("Graph",         "graph3d."),
    "L10n.Settings.tr":     ("Settings",      "settings."),
    "L10n.AI.tr":           ("AITasks",       "ai."),
    "L10n.AI.Task.tr":      ("AITasks",       "aitask."),
    "L10n.AI.Task.trf":     ("AITasks",       "aitask."),
    "L10n.Backup.tr":       ("Backup",        "backup."),
    "L10n.Backup.trf":      ("Backup",        "backup."),
    "L10n.Ingest.tr":       ("Ingest",        "ingest."),
    "L10n.Ingest.trf":      ("Ingest",        "ingest."),
    "L10n.Action.tr":       ("Actions",       "action."),
    "L10n.Common.tr":       ("Common",        "misc."),
    "L10n.Common.trf":      ("Common",        "misc."),
    "L10n.Common.Empty.tr": ("Common",        "empty."),
    "L10n.Accessibility.tr":("Accessibility", "a11y."),
    "L10n.Chat.tr":         ("Chat",          "chat."),
    "L10n.Chat.trf":        ("Chat",          "chat."),
    "L10n.Components.tr":   ("Components",    "backlinks."),
    "L10n.Watch.tr":        ("Watch",         "watch."),
    "L10n.Schema.tr":       ("Schema",        "schema."),
    "L10n.CoreModels.tr":   ("CoreModels",    ""),
    "L10n.Collaboration.tr":("Collaboration", "collab."),
    "L10n.Widget.tr":       ("Widget",        "widget."),
    "L10n.Transfer.tr":     ("Transfer",      ""),
    "L10n.Transfer.trf":    ("Transfer",      ""),
    "L10n.Transfer.Export.tr":  ("Transfer",  "export."),
    "L10n.Transfer.Import.tr":  ("Transfer",  "import."),
    "L10n.Coachmark.tr":    ("Coachmark",     "coachmark."),
    "L10n.Creation.tr":     ("Creation",      "create."),
    "L10n.Dashboard.tr":    ("Dashboard",     "dashboard."),
    "L10n.Dashboard.System.tr": ("Dashboard", "dashboard.stats.system."),
    "L10n.Editor.tr":       ("Editor",        "editor."),
    "L10n.ICloud.tr":       ("ICloud",        "icloud."),
    "L10n.Lint.tr":         ("Lint",          "lint."),
    "L10n.Lint.trf":        ("Lint",          "lint."),
    "L10n.Synthesis.tr":    ("Localizable",   "synthesis."),
    "L10n.Synthesis.trf":   ("Localizable",   "synthesis."),
    "L10n.Tag.tr":          ("Localizable",   "tag."),
    "L10n.Log.tr":          ("Localizable",   "log."),
    # Localized.tr 直接调用
    "Localized.tr":         (None,            ""),   # 需要特殊处理
    "L10n.Ingest.tr":       ("Ingest",        "ingest."),
}

# ──────────────────────────────────────────
# 1. 加载所有 .xcstrings 文件中已定义的键
# ──────────────────────────────────────────
defined_keys = {}   # { "TableName": set(keys) }

for xcs_path in L10N_DIR.glob("*.xcstrings"):
    table_name = xcs_path.stem
    try:
        with open(xcs_path, encoding="utf-8") as f:
            data = json.load(f)
        keys = set(data.get("strings", {}).keys())
        defined_keys[table_name] = keys
    except Exception as e:
        print(f"⚠️  无法解析 {xcs_path.name}: {e}")

# 也加载 Localizable
localizable = L10N_DIR / "Localizable.xcstrings"
if localizable.exists():
    try:
        with open(localizable, encoding="utf-8") as f:
            data = json.load(f)
        defined_keys["Localizable"] = set(data.get("strings", {}).keys())
    except Exception as e:
        print(f"⚠️  无法解析 Localizable.xcstrings: {e}")

# ──────────────────────────────────────────
# 2. 扫描所有 Swift 源文件，提取 .tr() / .trf() 调用
# ──────────────────────────────────────────
# 匹配: L10n.Ingest.tr("someKey") 或 L10n.Ingest.trf("someKey", ...)
# 也匹配: Localized.tr("key", table: "TableName")
CALL_PATTERN = re.compile(
    r'(L10n(?:\.\w+)+\.trf?|Localized\.trf?)\s*\(\s*"([^"]+)"(?:\s*,\s*table:\s*"([^"]+)")?'
)

findings = []  # (file, line_no, full_call, resolved_key, table)

def resolve_key(caller: str, short_key: str, explicit_table: str | None):
    """根据调用者前缀解析完整键名和表名"""
    if caller == "Localized.tr" or caller == "Localized.trf":
        # 显式 table 参数
        table = explicit_table or "Localizable"
        return short_key, table

    # L10n.xxx.tr / trf
    for prefix, (table, key_prefix) in L10N_TABLE_MAP.items():
        if caller == prefix:
            full_key = key_prefix + short_key
            return full_key, table or "Localizable"

    return None, None

for swift_file in SOURCES_DIR.rglob("*.swift"):
    try:
        content = swift_file.read_text(encoding="utf-8")
    except Exception:
        continue

    for line_no, line in enumerate(content.splitlines(), 1):
        for m in CALL_PATTERN.finditer(line):
            caller     = m.group(1)
            short_key  = m.group(2)
            expl_table = m.group(3)

            full_key, table = resolve_key(caller, short_key, expl_table)
            if full_key is None:
                continue

            findings.append((swift_file, line_no, caller, short_key, full_key, table))

# ──────────────────────────────────────────
# 3. 交叉比对，输出缺失清单
# ──────────────────────────────────────────
missing = []

for (swift_file, line_no, caller, short_key, full_key, table) in findings:
    table_keys = defined_keys.get(table)
    if table_keys is None:
        # 表文件本身不存在
        missing.append({
            "file": str(swift_file.relative_to(PROJECT_ROOT)),
            "line": line_no,
            "caller": caller,
            "key": full_key,
            "table": table,
            "reason": "table_not_found"
        })
        continue

    if full_key not in table_keys:
        # 尝试 Localizable 作为兜底
        if full_key in defined_keys.get("Localizable", set()):
            continue  # fallback 成功，不算缺失
        missing.append({
            "file": str(swift_file.relative_to(PROJECT_ROOT)),
            "line": line_no,
            "caller": caller,
            "key": full_key,
            "table": table,
            "reason": "key_not_found"
        })

# ──────────────────────────────────────────
# 4. 去重 + 输出
# ──────────────────────────────────────────
seen = set()
unique_missing = []
for m in missing:
    sig = (m["key"], m["table"])
    if sig not in seen:
        seen.add(sig)
        unique_missing.append(m)

print(f"\n{'='*60}")
print(f"全工程本地化缺失键扫描结果")
print(f"{'='*60}")
print(f"共扫描调用: {len(findings)} 处")
print(f"缺失键 (去重): {len(unique_missing)} 个\n")

if not unique_missing:
    print("✅ 未发现缺失的本地化键！")
else:
    # 按 table 分组输出
    by_table = {}
    for m in unique_missing:
        by_table.setdefault(m["table"], []).append(m)

    for table, items in sorted(by_table.items()):
        print(f"📁 表: {table}.xcstrings  ({len(items)} 个缺失)")
        print(f"{'─'*55}")
        for item in sorted(items, key=lambda x: x["key"]):
            reason_label = "键不存在" if item["reason"] == "key_not_found" else "表文件不存在"
            print(f"  ❌ {item['key']:<50} [{reason_label}]")
            print(f"     └─ {item['file']}:{item['line']}")
        print()

print(f"{'='*60}")
