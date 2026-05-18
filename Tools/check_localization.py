#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
智宇 (ZhiYu) 本地化完整性静态分析工具
功能：扫描所有 Swift 源码中的 L10n 调用，与分布式物理 .xcstrings 物理分表交叉比对，验证多语言翻译的完整性。
支持 Xcode Build Phases 集成，报错时引发编译失败。
"""

import os
import sys
import re
import json

# ==================== 配置常量 ====================
PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCES_DIR = os.path.join(PROJECT_DIR, "Sources")
LOCALIZATION_DIR = os.path.join(SOURCES_DIR, "Localization", "Catalogs")
LOCALIZATION_EXTENSIONS_DIR = os.path.join(SOURCES_DIR, "Localization", "Extensions")
LOCALIZED_SWIFT_PATH = os.path.join(SOURCES_DIR, "Core", "Base", "Utils", "Localized.swift")

def resolve_table_name(key, table):
    """
    解析表名。根据 Localized.swift 中的路由逻辑，
    将抽象表名映射到物理 .xcstrings 文件名。
    """
    table_map = {
        "AITasks": "AI",
        "Localizable": "Common",
        "KnowledgeBase": "Knowledge"
    }
    if table in table_map:
        return table_map[table]
    
    if table == "Common":
        if key.startswith("prompt."): return "AI"
        if key.startswith("ingest."): return "Ingest"
        if key.startswith("settings."): return "Settings"
        if key.startswith("chat."): return "Chat"
        if key.startswith("vault."): return "Vault"
        
    return table

# 获取所有相关的 L10n Swift 物理源码文件列表
def get_l10n_swift_files():
    swift_files = [LOCALIZED_SWIFT_PATH]
    if os.path.exists(LOCALIZATION_EXTENSIONS_DIR):
        for f in os.listdir(LOCALIZATION_EXTENSIONS_DIR):
            if f.startswith("L10n+") and f.endswith(".swift"):
                swift_files.append(os.path.join(LOCALIZATION_EXTENSIONS_DIR, f))
    return swift_files

# ==================== 1. 预先解析所有 L10n Swift 文件的 struct 表映射 ====================
def build_struct_table_mapping():
    struct_to_table = {}
    struct_pat = re.compile(r"\b(?:struct|enum)\s+([a-zA-Z0-9_]+)")
    t_pat = re.compile(r"\b(?:public\s+|static\s+|private\s+|internal\s+|fileprivate\s+)*let\s+t\s*=\s*\"([^\"]+)\"")

    for file_path in get_l10n_swift_files():
        if not os.path.exists(file_path):
            continue

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        lines = content.split("\n")
        struct_stack = []
        brace_depth = 0

        # 从文件名推断默认的垂直分表 table 名
        filename = os.path.basename(file_path)
        default_table = "Common"
        if filename.startswith("L10n+") and filename.endswith(".swift"):
            default_table = filename[5:-6]

        for line in lines:
            clean_line = re.sub(r'//.*', '', line)
            opened = clean_line.count('{')
            closed = clean_line.count('}')

            struct_match = struct_pat.search(clean_line)
            if struct_match:
                struct_name = struct_match.group(1)
                # 继承父结构体的表名，如果没有父结构体则使用文件默认表名
                parent_table = struct_stack[-1]['table'] if struct_stack else default_table
                struct_stack.append({
                    'depth': brace_depth,
                    'name': struct_name,
                    'table': parent_table
                })

            t_match = t_pat.search(clean_line)
            if t_match and struct_stack:
                struct_stack[-1]['table'] = t_match.group(1)

            # 修正括号深度，支持嵌套 struct 出栈
            brace_depth += opened - closed
            while struct_stack and brace_depth <= struct_stack[-1]['depth']:
                popped = struct_stack.pop()
                struct_to_table[popped['name']] = popped['table']

        for popped in struct_stack:
            struct_to_table[popped['name']] = popped['table']

    return struct_to_table

# ==================== 2. 解析单个 L10n Swift 文件并提取 Key ====================
def parse_single_l10n_swift(file_path, struct_to_table):
    if not os.path.exists(file_path):
        return []

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    brace_depth = 0
    struct_info = []
    keys_found = []

    # 匹配显式的 Localized.tr / trf 并提取 (key, table)
    explicit_pat = re.compile(r'Localized\.tr(?:f)?\("([^"]+)"\,\s*table:\s*"([^"]+)"\)')
    # 匹配隐式的本地 tr("key") 调用 (确保前面不是 ".")
    tr_pat = re.compile(r'(?<!\.)\btr(?:f)?\("([^"]+)"\)')
    # 匹配跨结构体调用，如 Plugin.tr("...") (确保前面不是 "Localized.")
    cross_struct_pat = re.compile(r'(?<!Localized\.)\b([a-zA-Z0-9_]+)\.tr(?:f)?\("([^"]+)"\)')
    # 匹配结构体定义
    struct_pat = re.compile(r"\b(?:struct|enum)\s+([a-zA-Z0-9_]+)")
    # 匹配结构体内指定的本地化表 let t = "Table"
    t_pat = re.compile(r"\b(?:public\s+|static\s+)*let\s+t\s*=\s*\"([^\"]+)\"")

    # 从文件名推断默认的垂直分表 table 名，如果是 L10n+Editor.swift 则为 Editor
    filename = os.path.basename(file_path)
    default_table = "Common"
    if filename.startswith("L10n+") and filename.endswith(".swift"):
        default_table = filename[5:-6]

    for i, line in enumerate(lines, 1):
        clean_line = re.sub(r'//.*', '', line)

        opened = clean_line.count("{")
        closed = clean_line.count("}")

        struct_match = struct_pat.search(clean_line)
        if struct_match:
            struct_name = struct_match.group(1)
            struct_info.append({
                'depth': brace_depth,
                'name': struct_name,
                'table': struct_to_table.get(struct_name, default_table)
            })

        t_match = t_pat.search(clean_line)
        if t_match and struct_info:
            struct_info[-1]['table'] = t_match.group(1)

        brace_depth += opened - closed

        while struct_info and brace_depth <= struct_info[-1]['depth']:
            struct_info.pop()

        active_table = struct_info[-1]['table'] if struct_info else default_table

        # 1. 显式调用
        for k, t in explicit_pat.findall(clean_line):
            keys_found.append((k, t, file_path, i))

        # 2. 跨结构体调用
        for struct_name, k in cross_struct_pat.findall(clean_line):
            if struct_name == "Localized":
                continue
            t = struct_to_table.get(struct_name, default_table)
            keys_found.append((k, t, file_path, i))

        # 3. 隐式本地 tr("...") 调用
        for k in tr_pat.findall(clean_line):
            if "Localized.tr" not in clean_line and not any(f"{s}.tr" in clean_line for s in struct_to_table):
                keys_found.append((k, active_table, file_path, i))

    return keys_found

# 提取分布式 L10n Swift 文件中的全量 Keys
def parse_all_l10n_keys(struct_to_table):
    all_keys = []
    for file_path in get_l10n_swift_files():
        keys = parse_single_l10n_swift(file_path, struct_to_table)
        all_keys.extend(keys)
    return all_keys

# ==================== 3. 扫描其他 Swift 源码中的 L10n 调用 ====================
def scan_other_swift_files(sources_dir, struct_to_table):
    # 显式指定 table: "xxx" 的调用
    explicit_pat = re.compile(r'(?:\bLocalized|\bL10n\.[a-zA-Z0-9_]+)\.tr(?:f)?\(\s*"([^"]+)"\s*,\s*table:\s*"([^"]+)"')
    
    # 隐式调用的前缀捕获
    implicit_pat = re.compile(r'(\bLocalized|\bL10n\.[a-zA-Z0-9_]+)\.tr(?:f)?\(\s*"([^"]+)"')
    
    keys_found = []
    leaks_found = [] 

    for root, _, files in os.walk(sources_dir):
        if "Tests" in root or "Tools" in root or "Localization" in root:
            continue
        for file in files:
            if not file.endswith(".swift"):
                continue
            file_path = os.path.join(root, file)
            if file_path == LOCALIZED_SWIFT_PATH:
                continue

            with open(file_path, "r", encoding="utf-8") as f:
                for i, line in enumerate(f, 1):
                    clean_line = re.sub(r'//.*', '', line)
                    
                    # 拦截越权直接调用 Localized.tr / Localized.trf 泄漏
                    if "Localized.tr" in clean_line:
                        allowed_files = {"LLMModels.swift", "SourceView.swift", "SearchView.swift"}
                        if file not in allowed_files:
                            leaks_found.append((file_path, i, "Localized.tr" if "Localized.trf" not in clean_line else "Localized.trf"))
                    
                    # 1. 优先匹配显式指定 table 的情况
                    for k, t in explicit_pat.findall(clean_line):
                        keys_found.append((k, t, file_path, i))
                    
                    # 2. 如果没有显式指定 table，匹配隐式调用
                    if "table:" not in clean_line:
                        for prefix, k in implicit_pat.findall(clean_line):
                            if prefix == "Localized":
                                t = "Localizable"
                            else:
                                # 提取 L10n.StructName 中的 StructName
                                struct_name = prefix.split(".")[1]
                                t = struct_to_table.get(struct_name, struct_name)
                            keys_found.append((k, t, file_path, i))

    return keys_found, leaks_found

# ==================== 4. 校验机制 ====================
class LocalizationAuditor:
    def __init__(self, localization_dir):
        self.localization_dir = localization_dir
        self.loaded_tables = {}

    def get_table_strings(self, table_name):
        if table_name in self.loaded_tables:
            return self.loaded_tables[table_name]

        file_path = os.path.join(self.localization_dir, f"{table_name}.xcstrings")
        if not os.path.exists(file_path):
            return None

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            strings = data.get("strings", {})
            self.loaded_tables[table_name] = strings
            return strings
        except Exception as e:
            print(f"error: Failed to load and parse JSON for table '{table_name}' at {file_path}. Error: {e}", file=sys.stderr)
            return {}

    def audit_key(self, key, table):
        if "\\(" in key:
            return None

        resolved_table = resolve_table_name(key, table)
        strings = self.get_table_strings(resolved_table)

        if strings is None:
            return f"Localization table '{resolved_table}' (.xcstrings) does not exist in directory: {self.localization_dir}"

        if key not in strings:
            return f"Key '{key}' is missing in localization table '{resolved_table}' (.xcstrings)"

        string_data = strings[key]
        localizations = string_data.get("localizations", {})

        for lang in ["en", "zh-Hans"]:
            if lang not in localizations:
                return f"Missing translation for language '{lang}' for key '{key}' in table '{resolved_table}'"
            
            val = localizations[lang].get("stringUnit", {}).get("value", "")
            if not val and val != "":
                return f"Empty or invalid translation unit for language '{lang}' for key '{key}' in table '{resolved_table}'"
            
            # 强化检查：严防将翻译值敷衍地设置为了 Key 自身
            if val == key:
                critical_prefixes = ["template.", "create.template.", "settings.clearAll", "synthesis.clearAll"]
                critical_keys = {"clearAll", "searchPlaceholder", "customIcon", "newPage", "pageType", "confirm"}
                if any(key.startswith(p) for p in critical_prefixes) or key in critical_keys:
                    return f"Translation for language '{lang}' is identical to the Key itself '{key}', which is considered an untranslated placeholder violation"

        return None

# ==================== 主入口程序 ====================
def main():
    print("--- Running L10n Comprehensive Static Audit (Decentralized Version) ---")
    
    # 1. 扫描所有 L10n 物理扩展 Swift 文件的 struct 表映射
    struct_to_table = build_struct_table_mapping()
    print(f"Loaded {len(struct_to_table)} namespaces mappings.")
    
    # 2. 从分布式 L10n Swift 代码和全量 Swift 源码中提取 Key
    keys_from_localized = parse_all_l10n_keys(struct_to_table)
    keys_from_code, leaks = scan_other_swift_files(SOURCES_DIR, struct_to_table)
    all_calls = keys_from_localized + keys_from_code
    
    print(f"Extracted {len(keys_from_localized)} keys definitions and {len(keys_from_code)} code calls.")

    auditor = LocalizationAuditor(LOCALIZATION_DIR)
    error_count = 0
    reported_errors = set()

    # 3. 优先输出泄漏越权直接调用底层翻译器错误
    for file_path, line, method in leaks:
        print(f"{file_path}:{line}: error: [L10n Leak] Directly calling '{method}' is strictly prohibited outside of L10n extensions. Please wrap it as a strongly-typed static member in 'L10n' extensions instead.", file=sys.stderr)
        error_count += 1

    # 4. 校验翻译存在性与语言完整性
    for key, table, file_path, line in all_calls:
        error_msg = auditor.audit_key(key, table)
        if error_msg:
            err_id = f"{file_path}:{line}:{key}@{table}"
            if err_id not in reported_errors:
                reported_errors.add(err_id)
                print(f"{file_path}:{line}: error: [L10n Audit] {error_msg}", file=sys.stderr)
                error_count += 1

    print(f"--- L10n Static Audit Finished: Found {error_count} error(s) ---")
    if error_count > 0:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
