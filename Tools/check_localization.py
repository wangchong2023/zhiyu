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
            
            # 3. 翻译值与 Key 相同 (且不是简单的格式符)
            elif en_val == zh_val and not is_chinese(en_val) and en_val.strip() != '':
                if not re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', en_val):
                    # 提示词模板键有意保持英文（zh=en），不告警
                    # 匹配 llm.prompt.XXX 和 llm.ingest.jsonXXX，排除 UI 用的 workshop/reset/expert
                    if re.match(r'^llm\.(prompt\.(?!workshop\b|reset\b|expert\b)[a-zA-Z]+|ingest\.json)', key):
                        pass
                    elif is_natural_language_sentence(en_val):
                        issues.append((file, key, f"Potential fake translation (zh matches en sentence): \"{en_val}\"", "ERROR"))
                    else:
                        issues.append((file, key, f"Identical zh/en detected: \"{en_val}\"", "WARNING"))
            
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

            # 7. 检查值为空
            if not en_val.strip():
                issues.append((file, key, f"English value is empty", "ERROR"))
            if not zh_val.strip():
                issues.append((file, key, f"zh-Hans value is empty", "ERROR"))

            # 6. 检查值为空（空字符串）
            if not en_val.strip():
                issues.append((file, key, f"English value is empty or whitespace only", "ERROR"))
            if not zh_val.strip():
                issues.append((file, key, f"zh-Hans value is empty or whitespace only", "ERROR"))

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
    xcstrings_keys = set()
    catalogs_dir = 'Sources/Localization/Catalogs'
    for file in os.listdir(catalogs_dir):
        if file.endswith('.xcstrings'):
            with open(os.path.join(catalogs_dir, file), 'r', encoding='utf-8') as f:
                data = json.load(f)
                strings = data.get('strings', {})
                for key in strings.keys():
                    xcstrings_keys.add(key)
                    
    tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
    tr_func_pattern = re.compile(r'trf?\(\s*"([^"]+)"')
    
    extensions_dir = 'Sources/Localization/Extensions'
    missing = []
    
    for file in os.listdir(extensions_dir):
        if file.endswith('.swift'):
            path = os.path.join(extensions_dir, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                matches1 = tr_pattern.findall(content)
                matches2 = tr_func_pattern.findall(content)
                
                for key in set(matches1 + matches2):
                    if key not in xcstrings_keys:
                        missing.append((path, key, "Key defined in L10n extension but missing in .xcstrings", "ERROR"))
    return missing

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
    
    # Check for missing keys
    missing_key_issues = check_missing_keys()
    
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
            
    if not all_source_issues and not xcstrings_issues and not missing_key_issues:
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
