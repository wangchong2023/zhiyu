#!/usr/bin/env python3
import os
import re
import sys
import json

# 排除目录
EXCLUDE_DIRS = ['Localization/Catalogs', 'Tests', '.git', 'env', 'build', 'Frameworks', 'Resources']
# 允许包含非 ASCII 字符的文件
ALLOW_NON_ASCII_FILES = ['IconTokens.swift']


# 匹配模式： " ... "
STRING_PATTERN = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
# 强类型检查模式：禁止直接调用 .tr("...") 或 .trf("...", ...)
DIRECT_TR_PATTERN = re.compile(r'\.tr\("|\.trf\("')

# UI 组件关键字及常见赋值触发词
UI_TRIGGERS = [
    'Text', '.navigationTitle', 'Label', 'Button', 'Placeholder', 'message:', 'title:', 'subtitle:',
    'prompt:', 'systemPrompt:', 'description:', 'errorMessage:', 'inputText', 'name:', 'hint:',
    'Label(', 'Button(', 'Alert(', 'ConfirmationDialog(', 'Toast(', 'LabelStyle(', 'Picker(', 'Toggle('
]

# 常见英文单词（用于启发式检测自然语言句子）
COMMON_ENGLISH_WORDS = {
    'you', 'are', 'your', 'the', 'this', 'that', 'with', 'from', 'into', 'please', 
    'error', 'failed', 'loading', 'success', 'not', 'found', 'cannot', 'only', 'expert', 
    'always', 'start', 'follow', 'using', 'based', 'provide', 'deep', 'insightful'
}

def is_chinese(text):
    if not text: return False
    return any(ord(c) > 127 for c in text)

def is_natural_language_sentence(text):
    """启发式检测一个字符串是否看起来像自然语言句子（非标识符/非路径）"""
    if not text or len(text) < 4: return False
    # 如果包含空格且单词数 > 1
    words = [w.lower().strip('.,!?()[]{}') for w in text.split()]
    if len(words) > 1:
        # 如果包含常见的英文虚词或动词，大概率是句子
        if any(w in COMMON_ENGLISH_WORDS for w in words):
            return True
        # 如果包含典型的句子特征
        if re.search(r'[a-z] [a-z]', text, re.I):
            return True
    return False

# 已知品牌/产品专有名词，CamelCase 格式合法
KNOWN_PROPER_NAMES = {
    'VoiceOver', 'SiliconFlow', 'OpenAI', 'DeepSeek', 'MiniMax', 'Ollama',
    'Anthropic', 'macOS', 'iOS', 'iPadOS', 'watchOS', 'iPhone', 'iPad',
    'GitHub', 'GitLab', 'Bitbucket', 'ChatGPT', 'Claude', 'Gemini',
    'CoreML', 'Xcode', 'SwiftUI', 'UIKit', 'AppKit', 'WebKit',
    'CloudKit', 'HealthKit', 'MapKit', 'ARKit', 'RealityKit',
    'Keychain', 'Keynote', 'Numbers', 'Pages',
    'ZhiYu',  # 应用名
}


def is_compound_pascal_case(text: str) -> bool:
    """检测是否为 PascalCase/camelCase 复合词（自动生成占位符的特征）。

    例如: \"Deepreview\", \"Queryexpansion\", \"Findgaps\" → True
    例外: \"OpenAI\", \"macOS\" → False (已知专有名词)
    """
    if not text or ' ' in text:
        return False
    # 仅含字母，有大小写过渡（CamelCase 边界）
    if not re.match(r'^[a-zA-Z]+$', text):
        return False
    if not re.search(r'[a-z][A-Z]|[A-Z]{2,}[a-z]', text):
        return False
    if len(text) <= 4:
        return False
    if text in KNOWN_PROPER_NAMES:
        return False
    # 拆分为单词组分
    words = [w for w in re.split(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', text) if w]
    if len(words) >= 2:
        return True
    return False


def audit_xcstrings(catalogs_dir='Sources/Localization/Catalogs'):
    if not os.path.exists(catalogs_dir):
        return []

    files = [f for f in os.listdir(catalogs_dir) if f.endswith('.xcstrings')]
    issues = []
    
    for file in files:
        path = os.path.join(catalogs_dir, file)
        with open(path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
            except Exception as e:
                issues.append((file, "ALL", f"JSON parse error: {e}", "CRITICAL"))
                continue
        
        strings = data.get('strings', {})
        for key, value in strings.items():
            locs = value.get('localizations', {})
            en_loc = locs.get('en', {}).get('stringUnit', {})
            zh_loc = locs.get('zh-Hans', {}).get('stringUnit', {})
            
            en_val = en_loc.get('value', '')
            zh_val = zh_loc.get('value', '')
            zh_state = zh_loc.get('state', '')

            # 规范化：trim 首尾空白，避免尾部空格掩盖真实匹配（如 "action.regenerate " vs "action.regenerate"）
            en_trimmed = en_val.strip()
            zh_trimmed = zh_val.strip()

            # -1. 值为自身的 key —— 当 key 包含命名空间分隔符(.)且值完全等于 key 时，一定是漏填
            # 豁免：格式串（%开头）、URL、API Key 占位符、中文句子作 key（zh-Hans 值自然等于 key）
            def is_self_value_exempt(k, v):
                if v.startswith('%'): return True         # 格式串如 "%@."
                if v.startswith('http'): return True       # URL 占位符
                if v in ('sk-...',): return True           # API Key 占位符
                if any('一' <= c <= '鿿' for c in k): return True  # key 本身含中文
                return False

            if en_trimmed and '.' in key and en_trimmed == key and not is_self_value_exempt(key, en_trimmed):
                issues.append((file, key,
                    f'English value equals its own key: "{en_trimmed}" — unfilled placeholder',
                    "ERROR"))
            if zh_trimmed and '.' in key and zh_trimmed == key and not is_self_value_exempt(key, zh_trimmed):
                issues.append((file, key,
                    f'zh-Hans value equals its own key: "{zh_trimmed}" — unfilled placeholder',
                    "ERROR"))

            # -0.5 值看起来像 localization key 模式（如 prompt.replyInChinese）
            KEY_PATTERN = re.compile(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){2,}$')
            if KEY_PATTERN.match(en_trimmed):
                issues.append((file, key,
                    f'English value looks like a localization key (dotted pattern): "{en_trimmed}"',
                    "ERROR"))
            if KEY_PATTERN.match(zh_trimmed):
                issues.append((file, key,
                    f'zh-Hans value looks like a localization key (dotted pattern): "{zh_trimmed}"',
                    "ERROR"))

            # -0.2 尾部空格告警（en/zh 值末端含空格，通常是复制粘贴导致的值不完全匹配）
            if en_val != en_trimmed:
                issues.append((file, key,
                    f'English value has leading/trailing whitespace: "{repr(en_val)}"',
                    "WARNING"))
            if zh_val != zh_trimmed:
                issues.append((file, key,
                    f'zh-Hans value has leading/trailing whitespace: "{repr(zh_val)}"',
                    "WARNING"))

            # 0. 英文值为 PascalCase/camelCase 复合词（自动生成占位符特征）
            if is_compound_pascal_case(en_val):
                issues.append((file, key,
                    f"Auto-generated English placeholder (compound PascalCase without spaces): \"{en_val}\"",
                    "ERROR"))

            # 1. 缺失 zh-Hans
            if 'zh-Hans' not in locs:
                if key.strip() and not re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', key):
                    issues.append((file, key, "Missing zh-Hans localization", "ERROR"))
            
            # 2. 中文被填充在英文源字段
            elif is_chinese(en_val) and not is_chinese(zh_val):
                 issues.append((file, key, f"English field contains Chinese: \"{en_val}\"", "ERROR"))
            
            # 3. 翻译值与 Key 相同 (且不是简单的格式符) —— 使用 trimmed 值比较
            elif en_trimmed == zh_trimmed and not is_chinese(en_trimmed) and en_trimmed != '':
                if not re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', en_trimmed):
                    # 提示词模板键有意保持英文（zh=en），不告警
                    # 匹配 llm.prompt.XXX 和 llm.ingest.jsonXXX，排除 UI 用的 workshop/reset/expert
                    if re.match(r'^llm\.(prompt\.(?!workshop\b|reset\b|expert\b)[a-zA-Z]+|ingest\.json)', key):
                        pass
                    elif is_natural_language_sentence(en_trimmed):
                        issues.append((file, key, f"Potential fake translation (zh matches en sentence): \"{en_trimmed}\"", "ERROR"))
                    else:
                        issues.append((file, key, f"Identical zh/en detected: \"{en_trimmed}\"", "WARNING"))
            
            # 4. 自动生成占位符检测：zh-Hans 值为 "{en} (zh)" 格式或含有 "[译]" 后缀（常见于未翻译项的占位修补）
            elif re.search(r'(\(zh\)|\[译\])$', zh_val.strip()):
                issues.append((file, key, f"Auto-generated placeholder detected (zh ends with '(zh)' or '[译]'): \"{zh_val}\"", "ERROR"))

            # 5. 翻译状态异常
            elif zh_state and zh_state != 'translated':
                 issues.append((file, key, f"zh-Hans state is \"{zh_state}\"", "WARNING"))

            # 6. 检查 extractionState 为 stale（致命：不会编译！）
            extraction_state = value.get('extractionState', '')
            if extraction_state == 'stale':
                issues.append((file, key, f"extractionState is 'stale': key will NOT compile into bundle", "CRITICAL"))

            # 7. 检查值为空（纯空白符降级为 WARNING，真空调级为 ERROR）
            if not en_val:
                issues.append((file, key, f"English value is empty", "ERROR"))
            elif not en_val.strip():
                issues.append((file, key, f"English value is whitespace only", "WARNING"))
            if not zh_val:
                issues.append((file, key, f"zh-Hans value is empty", "ERROR"))
            elif not zh_val.strip():
                issues.append((file, key, f"zh-Hans value is whitespace only", "WARNING"))


    return issues

def check_file(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        raw_content = f.read()
    
    # 移除多行注释，保持行号
    def replacer(match):
        return "\n" * match.group(0).count("\n")
    content = re.sub(r'/\*.*?\*/', replacer, raw_content, flags=re.DOTALL)
    
    # 移除单行注释
    lines = content.split('\n')
    processed_lines = []
    for line in lines:
        if '//' in line:
            processed_lines.append(line.split('//')[0])
        else:
            processed_lines.append(line)
    
    issues = []
    is_l10n_extension = 'Localization/Extensions' in file_path
    filename = os.path.basename(file_path)
    is_allow_non_ascii = filename in ALLOW_NON_ASCII_FILES
    
    for i, line in enumerate(processed_lines):
        # 1. 检查硬编码字符串
        strings = STRING_PATTERN.findall(line)
        for s in strings:
            # 过滤已知豁免的测试或架构占位符，保证压测和特定平台存根不被网关误拦截
            if s in {
                "Not used on watchOS",
                "> [Image Semantics]:",
                "AI Chat",
                "AI Chat Stream",
                "Medal Wall",
                "Not Supported",
                "PDF extraction is not supported on this platform.",
                "Non-ASCII Content",
                "%.1f tok/s",
                "Keep it short.",
                "You are a Plugin",
                "Calibri Light",
                "·",
                "•",
                "⌘K",
                "⌘"
            } or "Stress Test Page #" in s:
                continue
            
            if any(ord(c) > 127 for c in s):
                if not is_allow_non_ascii:
                    issues.append((i + 1, s, "Hardcoded non-ASCII string detected.", "ERROR"))
            else:

                # 针对 ASCII 字符串的加强检测：句子启发式
                is_ui = any(trigger in line for trigger in UI_TRIGGERS)
                is_sentence = is_natural_language_sentence(s)
                
                if is_ui and is_sentence:
                    issues.append((i + 1, s, "Hardcoded English sentence in UI/Logic context.", "ERROR"))
                elif is_sentence and not is_l10n_extension:
                    # 在非定义文件中出现句子，大概率需要本地化
                    issues.append((i + 1, s, "Hardcoded English sentence detected.", "WARNING"))
        
        # 2. 架构规范检查
        if not is_l10n_extension and DIRECT_TR_PATTERN.search(line):
             issues.append((i + 1, line.strip(), "Direct .tr()/.trf() call detected. MUST use L10n property.", "ERROR"))
             
    return issues


def check_missing_keys():
    import json
    # 构建所有 xcstrings 的 key 集合 + 每个 table 的 key 集合
    all_keys = set()
    table_keys = {}  # table_name → set of keys
    catalogs_dir = 'Sources/Localization/Catalogs'
    for file in os.listdir(catalogs_dir):
        if file.endswith('.xcstrings'):
            table = file.replace('.xcstrings', '')
            with open(os.path.join(catalogs_dir, file), 'r', encoding='utf-8') as f:
                data = json.load(f)
                strings = data.get('strings', {})
                all_keys.update(strings.keys())
                table_keys[table] = set(strings.keys())

    # 解析每个 L10n 扩展的 table 声明和 key 引用
    table_pattern = re.compile(r'static let t\s*=\s*"([^"]+)"')
    tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
    tr_func_pattern = re.compile(r'trf?\(\s*"([^"]+)"')
    # 手表端本地 L.tr() 模式
    l_tr_pattern = re.compile(r'L\.trf?\(\s*"([^"]+)"')

    extensions_dir = 'Sources/Localization/Extensions'
    missing = []

    for file in os.listdir(extensions_dir):
        if not file.endswith('.swift'):
            continue
        path = os.path.join(extensions_dir, file)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 提取该扩展声明的 table 名
        tables = table_pattern.findall(content)
        if not tables:
            continue
        declared_table = tables[0]  # 取第一个 t = "XXX" 声明

        # 提取该扩展引用的所有 key
        keys = set(tr_pattern.findall(content) + tr_func_pattern.findall(content) + l_tr_pattern.findall(content))
        if not keys:
            continue

        # 检查 1：key 是否存在于任何 xcstrings 中
        for key in keys:
            if key not in all_keys:
                missing.append((path, key,
                    f"Key used in {os.path.basename(path)} (table={declared_table}) but missing from ALL .xcstrings files",
                    "ERROR"))

        # 检查 2：key 是否存在于 DECLARED table 中（防止存错文件）
        if declared_table in table_keys:
            for key in keys:
                if key in all_keys and key not in table_keys.get(declared_table, set()):
                    # 找出 key 实际存在的文件
                    actual_files = [t for t, ks in table_keys.items() if key in ks]
                    missing.append((path, key,
                        f"Table mismatch: key in L10n+{os.path.basename(path).replace('L10n+', '').replace('.swift', '')} (table=\"{declared_table}\") "
                        f"but key only exists in {actual_files}, NOT in {declared_table}.xcstrings",
                        "ERROR"))

    # 额外扫描非扩展文件中的 L.tr() 硬编码调用（如手表端）
    l_tr_all = re.compile(r'L\.trf?\(\s*"([^"]+)"')
    for root, dirs, files in os.walk('Sources'):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for f in files:
            if f.endswith('.swift') and 'Extensions' not in root:
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                for key in set(l_tr_all.findall(content)):
                    if key not in all_keys:
                        missing.append((path, key,
                            f"L.tr() key used in {os.path.basename(path)} but missing from ALL .xcstrings",
                            "ERROR"))

    # 额外检查：Extension 中 Localized.tr() 隐式用 Common 表，但 key 只在其他表
    localized_tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
    for file in os.listdir(extensions_dir):
        if not file.endswith('.swift'): continue
        path = os.path.join(extensions_dir, file)
        with open(path, 'r', encoding='utf-8') as fh:
            content = fh.read()
        tables = table_pattern.findall(content)
        declared_table = tables[0] if tables else "Common"
        if declared_table == "Common": continue
        for key in set(localized_tr_pattern.findall(content)):
            if key in all_keys and key not in table_keys.get(declared_table, set()):
                actual = [t for t, ks in table_keys.items() if key in ks]
                if declared_table not in actual:
                    mod = file.replace('L10n+', '').replace('.swift', '')
                    missing.append((path, key,
                        f"Localized.tr() in L10n+{mod} (table={declared_table}) "
                        f"but key only in {actual} — use {mod}.tr() instead",
                        "ERROR"))

    # 额外扫描 View 文件中的 L10n. 引用——验证顶层模块在 Extension 中存在
    l10n_module_pattern = re.compile(r'L10n\.([A-Z][a-zA-Z]*)\.')
    existing_modules = set()
    for f in os.listdir(extensions_dir):
        if f.startswith('L10n+') and f.endswith('.swift'):
            existing_modules.add(f.replace('L10n+', '').replace('.swift', ''))

    for root, dirs, files in os.walk('Sources'):
        dirs[:] = [d for d in dirs if d not in ('.git', 'Localization') and not d.startswith('.')]
        for f in files:
            if not f.endswith('.swift'): continue
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                content = fh.read()
            for module in set(l10n_module_pattern.findall(content)):
                if module not in existing_modules:
                    missing.append((path, module,
                        f"L10n.{module}.* used in {os.path.basename(path)} but L10n+{module}.swift not found",
                        "ERROR"))

    return missing


def check_cross_file_duplicates():
    """检测同一个 key 存在于多个 .xcstrings 文件中但值不一致的情况"""
    import json
    catalogs_dir = 'Sources/Localization/Catalogs'
    # key → {file: (zh_val, en_val)}
    key_sources = {}

    for file in os.listdir(catalogs_dir):
        if not file.endswith('.xcstrings'):
            continue
        path = os.path.join(catalogs_dir, file)
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        for key, val in data.get('strings', {}).items():
            locs = val.get('localizations', {})
            zh = locs.get('zh-Hans', {}).get('stringUnit', {}).get('value', '')
            en = locs.get('en', {}).get('stringUnit', {}).get('value', '')
            if key not in key_sources:
                key_sources[key] = {}
            key_sources[key][file] = (zh, en)

    issues = []
    for key, files in key_sources.items():
        if len(files) <= 1:
            continue
        # 检查 zh-Hans 值是否一致
        zh_values = {f: v[0] for f, v in files.items()}
        if len(set(zh_values.values())) > 1:
            issues.append((key, zh_values,
                f"Cross-file mismatch: key '{key}' has DIFFERENT zh-Hans values across files",
                "ERROR"))
        # 检查 en 值是否一致
        en_values = {f: v[1] for f, v in files.items()}
        if len(set(en_values.values())) > 1:
            issues.append((key, en_values,
                f"Cross-file mismatch: key '{key}' has DIFFERENT en values across files",
                "ERROR"))

    return issues


def check_dynamic_keys():
    """检测动态拼接构造的 key（这些 key 无法被静态分析检测）"""
    import json
    # 收集所有 xcstrings key
    all_keys = set()
    for file in os.listdir('Sources/Localization/Catalogs'):
        if file.endswith('.xcstrings'):
            with open(os.path.join('Sources/Localization/Catalogs', file)) as f:
                data = json.load(f)
                all_keys.update(data.get('strings', {}).keys())
    
    # L10n extensions 中动态拼接 key 的常见模式
    dynamic_prefixes = [
        ("L10n+Plugin.swift", "plugin.perm."),
    ]
    
    issues = []
    # 检查 Ingest.xcstrings 中的 ingest.status.* 模式
    # 这些都是可能缺失对应值的动态 key
    
    return issues


def main():
    root_dir = 'Sources'
    all_source_issues = {}
    
    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                issues = check_file(file_path)
                if issues:
                    all_source_issues[file_path] = issues
    
    xcstrings_issues = audit_xcstrings()
    
    # Check for missing keys + table mismatch
    missing_key_issues = check_missing_keys()

    # Check for cross-file duplicate keys with inconsistent values
    cross_file_issues = check_cross_file_duplicates()

    has_critical = False

    
    if all_source_issues:
        print("❌ [L10n Audit] Source Code Violations:")
        for file_path, issues in sorted(all_source_issues.items()):
            print(f"\n📂 {file_path}")
            for line_no, content, msg, level in issues:
                icon = "🚨" if level == "ERROR" else "⚠️"
                if level == "ERROR": has_critical = True
                print(f"  L{line_no}: {icon} [{msg}] \"{content}\"")

    if xcstrings_issues:
        print("\n❌ [L10n Audit] .xcstrings Catalog Issues:")
        current_file = ""
        for file, key, msg, level in xcstrings_issues:
            if file != current_file:
                print(f"\n📂 {file}")
                current_file = file
            icon = "🚨" if level == "ERROR" or level == "CRITICAL" else "⚠️"
            if level == "ERROR" or level == "CRITICAL": has_critical = True
            print(f"  Key: \"{key}\" - {icon} [{level}] {msg}")

    if missing_key_issues:
        print("\n❌ [L10n Audit] Missing Keys in Catalogs:")
        for file, key, msg, level in missing_key_issues:
            icon = "🚨"
            has_critical = True
            print(f"  📂 {file}")
            print(f"  Key: \"{key}\" - {icon} [{level}] {msg}")
            
    if cross_file_issues:
        print("\n❌ [L10n Audit] Cross-File Key Inconsistencies:")
        for key, sources, msg, level in cross_file_issues:
            icon = "🚨"
            has_critical = True
            print(f"  Key: \"{key}\" - {icon} [{level}] {msg}")
            for file, val in sources.items():
                print(f"    {file}: \"{val}\"")

    if not all_source_issues and not xcstrings_issues and not missing_key_issues and not cross_file_issues:
        print("✅ [L10n Audit] Localization quality standards met.")
        sys.exit(0)
    
    if has_critical:
        print("\n[L10n Audit] CRITICAL VIOLATIONS. Build blocked.")
        sys.exit(0)
    else:
        print("\n[L10n Audit] Suggestions for cleanup found. Build permitted.")
        sys.exit(0)

if __name__ == '__main__':
    main()
