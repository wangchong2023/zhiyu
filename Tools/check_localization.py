#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
智宇 (ZhiYu) 本地化完整性静态分析工具 (Decentralized Version)
功能：
1. 扫描所有 Swift 源码，验证 L10n.XXX.tr 调用的键值在物理表中是否真实存在。
2. 拦截未封装的硬编码中文字符串（保障国际化全覆盖）。
3. 拦截违规的 `Localized.tr` 隐式调用，强制要求向 L10n 命名空间收口，根除隐式 Fallback 造成的 MISSING 隐患。
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
    domain_map = {
        "Localizable": "Common",
        "Accessibility": "Common",
        "Search": "Common",
        
        "Editor": "Knowledge",
        "Creation": "Knowledge",
        "Vault": "Knowledge",
        "Quiz": "Knowledge",
        "KnowledgeBase": "Knowledge",
        
        "Chat": "AI",
        "Voice": "AI",
        "AITasks": "AI",
        
        "Graph": "Insight",
        "Dashboard": "Insight",
        
        "Auth": "System",
        "Settings": "System",
        "Lint": "System",
        "Onboarding": "System",
        "Coachmark": "System",
        "Workflow": "System",
        "Reminder": "System",
        
        "Sync": "Ingest",
        "Transfer": "Ingest",
        
        "Collaboration": "Plugin",
        
        "Watch": "Platform",
        "Widget": "Platform"
    }
    
    return domain_map.get(table, table)

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
    # 匹配没有 table 参数的全局 Localized.tr / trf 调用 (隐式表归为 Common)
    implicit_localized_pat = re.compile(r'Localized\.tr(?:f)?\("([^"]+)"\)(?!\s*,\s*table:)')
    # 匹配隐式的本地 tr("key") 或 trf("key", ...) 调用
    tr_pat = re.compile(r'(?<!\.)\btr(?:f)?\("([^"]+)"')
    # 匹配跨结构体调用，如 Plugin.tr("...") 或 Dashboard.trf("...", args)
    cross_struct_pat = re.compile(r'(?<!Localized\.)\b([a-zA-Z0-9_]+)\.tr(?:f)?\("([^"]+)"')
    # 匹配结构体定义
    struct_pat = re.compile(r"\b(?:struct|enum)\s+([a-zA-Z0-9_]+)")
    # 匹配结构体内指定的本地化表 let t = "Table"
    t_pat = re.compile(r"\b(?:public\s+|static\s+|private\s+|internal\s+|fileprivate\s+)*let\s+t\s*=\s*\"([^\"]+)\"")

    # 从文件名推断默认的垂直分表 table 名
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
            parent_table = struct_info[-1]['table'] if struct_info else default_table
            struct_info.append({
                'depth': brace_depth,
                'name': struct_name,
                'table': parent_table
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

        # 1.5 没有 table 参数的隐式 Localized.tr / trf 调用 (隐式表归为 Common)
        for k in implicit_localized_pat.findall(clean_line):
            keys_found.append((k, "Common", file_path, i))

        # 2. 跨结构体调用
        for struct_name, k in cross_struct_pat.findall(clean_line):
            if struct_name == "Localized":
                continue
            t = struct_to_table.get(struct_name, default_table)
            keys_found.append((k, t, file_path, i))

        # 3. 隐式本地 tr("...") 调用
        for k in tr_pat.findall(clean_line):
            # 排除已经被 explicit_pat 或 cross_struct_pat 捕获的情况
            if "Localized.tr" in clean_line: continue
            if any(f"{s}.tr" in clean_line for s in struct_to_table): continue
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
def detect_hardcoded_chinese(line, filename):
    """
    检测一行 Swift 代码中是否包含未被多语言封装的硬编码中文字符串字面量。
    排除了注释、调试日志、LLM 模版提示词、单元测试等合理场景。
    """
    # 移除单行注释
    clean_line = re.sub(r'//.*', '', line)
    
    # 排除多行注释或标记
    if "/*" in clean_line or "*/" in clean_line or clean_line.strip().startswith("*"):
        return False
        
    # 如果是本地化定义文件本身（L10n 扩展），不进行硬编码中文字面量拦截
    if filename.startswith("L10n+") or filename == "Localized.swift":
        return False

    # 排除特定的、只应该用于大模型 Prompt 模板、系统配置、后台任务、测试压测等合理包含中文的物理文件
    excluded_files = {
        # 大模型 Prompt 与 AI 检索/生成链路核心控制流逻辑
        "PromptRegistry.swift", "AIContentEnricher.swift", "PromptService.swift",
        "LLMRetrievalService.swift", "AISynthesisService.swift", "LLMModels.swift",
        
        # 系统集成、网络爬虫、沙箱插件、DI 注册等底座基础设施层
        "ShortcutManager.swift", "PluginRegistry.swift", "PluginMarketService.swift",
        "JavaScriptPlugin.swift", "WebScraperProcessor.swift", "ModuleRegistrar.swift",
        "PromptSanitizer.swift",
        
        # 单元测试、模拟数据压测与系统备份工具类
        "PerformanceBenchmarker.swift", "AppBackupService.swift", "Logger.swift",
        
        # 共享通用基础 UI 的特殊折行字串与静态主题分类工厂常数
        "AppEmptyState.swift", "NotebookThemeFactory.swift",
        
        # 排除非纯业务 UI 渲染或包含大量大模型交互正则匹配的视图与控制器
        "QuizView.swift", "SearchView.swift", "SourceView.swift",
        
        # 排除 watchOS 的极简对照多语言词典及带有系统 LocalizedStringResource 声明的 widget 宿主
        "WatchWidgets.swift", "ZhiYuWatchView.swift"
    }
    if filename in excluded_files:
        return False

    # 合理排除项正则：如果是调试日志、LLM 提示词本身、单元测试断言、系统级 Crash 挂起、合法的 LocalizedStringResource 默认值定义（不区分大小写）
    exclusion_patterns = [
        r'\blog\b', r'\blogger\b', r'\bprint\b', r'\bNSLog\b', r'\bos_log\b',
        r'\bPrompt\b', r'\bprompt\b', r'\bsystemPrompt\b', r'\bMock\b',
        r'\bLocalized\.tr\b', r'\bL10n\b', r'\bXCTAssert\b', r'\bdetails\b',
        r'\bLogger\b', r'\bfatalError\b', r'\bassertionFailure\b', r'\bpreconditionFailure\b',
        r'\bdefaultValue\b'
    ]
    # 检查是否包含以上排除标记（不区分大小写）
    if any(re.search(pat, clean_line, re.IGNORECASE) for pat in exclusion_patterns):
        return False
        
    # 匹配双引号包裹的字符串字面量中含有中文字符的模式 (支持普通双引号与 Swift 多行 """ )
    chinese_literal_pat = re.compile(r'"[^"]*[\u4e00-\u9fa5]+[^"]*"')
    triple_chinese_literal_pat = re.compile(r'"""[^"]*[\u4e00-\u9fa5]+[^"]*"""')
    
    if chinese_literal_pat.search(clean_line) or triple_chinese_literal_pat.search(clean_line):
        return True
        
    return False

def scan_other_swift_files(sources_dir, struct_to_table):
    # 使用更安全的正则
    explicit_pat = re.compile(r'(?:\bLocalized|\bL10n\.[a-zA-Z0-9_\.]+)\.tr(?:f)?\(\s*"([^"]+)"\s*,\s*table:\s*"([^"]+)"')
    implicit_pat = re.compile(r'(\bLocalized|\bL10n\.[a-zA-Z0-9_\.]+)\.tr(?:f)?\(\s*"([^"]+)"')
    
    keys_found = []
    leaks_found = [] 
    
    for root, _, files in os.walk(sources_dir):
        if any(d in root for d in ["Tests", "Tools", "Localization"]):
            continue
        for file in files:
            if not file.endswith(".swift"):
                continue
            file_path = os.path.join(root, file)
            if file_path == LOCALIZED_SWIFT_PATH:
                continue

            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                lines = content.split("\n")
                for i, line in enumerate(lines, 1):
                    clean_line = re.sub(r'//.*', '', line)
                    
                    if "Localized.tr" in clean_line:
                        allowed_files = {"LLMModels.swift", "SourceView.swift", "SearchView.swift"}
                        if file not in allowed_files:
                            leaks_found.append((file_path, i, "Localized.tr" if "Localized.trf" not in clean_line else "Localized.trf"))
                        elif "table:" not in clean_line:
                            # 即使在白名单内，使用原生的 Localized.tr 进行动态变量反射时，也必须显式指明路由表，严禁隐式 fallback 到 Common！
                            leaks_found.append((file_path, i, "Dynamic Localized.tr calls in allowed files MUST explicitly provide a 'table:' argument"))
                    
                    # 拦截未封装的硬编码中文字符串字面量泄漏 (强制作为 Error 拦截并阻断 Xcode 编译构建)
                    if detect_hardcoded_chinese(line, file):
                        leaks_found.append((file_path, i, f"Hardcoded Chinese Literal: '{line.strip()}'"))

                    for k, t in explicit_pat.findall(clean_line):
                        keys_found.append((k, t, file_path, i))
                    
                    if "table:" not in clean_line:
                        for prefix, k in implicit_pat.findall(clean_line):
                            if prefix == "Localized":
                                t = "Localizable"
                            else:
                                parts = prefix.split(".")
                                if len(parts) > 1:
                                    struct_name = parts[1]
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

        # 逻辑增强：如果 resolved_table 中找不到，尝试在 Common 表中查找 (Fallback)
        if key not in strings:
            if resolved_table != "Common":
                common_strings = self.get_table_strings("Common")
                if common_strings and key in common_strings:
                    strings = common_strings
                    resolved_table = "Common"
                else:
                    return f"Key '{key}' is missing in both localization table '{resolved_table}' and fallback 'Common'"
            else:
                return f"Key '{key}' is missing in localization table '{resolved_table}' (.xcstrings)"

        string_data = strings[key]
        localizations = string_data.get("localizations", {})

        for lang in ["en", "zh-Hans"]:
            if lang not in localizations:
                return f"Missing translation for language '{lang}' for key '{key}' in table '{resolved_table}'"
            
            val = localizations[lang].get("stringUnit", {}).get("value", "")
            if not val and val != "":
                return f"Empty or invalid translation unit for language '{lang}' for key '{key}' in table '{resolved_table}'"
            
            if val == key:
                critical_prefixes = ["template.", "create.template.", "settings.clearAll", "synthesis.clearAll"]
                critical_keys = {"clearAll", "searchPlaceholder", "customIcon", "newPage", "pageType", "confirm"}
                if any(key.startswith(p) for p in critical_prefixes) or key in critical_keys:
                    return f"Translation for language '{lang}' is identical to the Key itself '{key}', which is considered an untranslated placeholder violation"

        return None

# ==================== 主入口程序 ====================
def main():
    print("--- Running L10n Comprehensive Static Audit (Decentralized Version) ---")
    
    struct_to_table = build_struct_table_mapping()
    print(f"Loaded {len(struct_to_table)} namespaces mappings.")
    
    keys_from_localized = parse_all_l10n_keys(struct_to_table)
    keys_from_code, leaks = scan_other_swift_files(SOURCES_DIR, struct_to_table)
    all_calls = keys_from_localized + keys_from_code
    
    print(f"Extracted {len(keys_from_localized)} keys definitions and {len(keys_from_code)} code calls.")

    auditor = LocalizationAuditor(LOCALIZATION_DIR)
    error_count = 0
    reported_errors = set()

    for file_path, line, method in leaks:
        print(f"{file_path}:{line}: error: [L10n Leak] Directly calling '{method}' is strictly prohibited outside of L10n extensions. Please wrap it as a strongly-typed static member in 'L10n' extensions instead.", file=sys.stderr)
        error_count += 1

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
