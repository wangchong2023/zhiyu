#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  check_localization.py
#  ZhiYu
#
#  Created by Antigravity on 2026/06/12.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：[Tools/Gatekeeper] 守卫网关
#  核心职责：提供一整套面向对象的高保真本地化（L10n）静态审计引擎。
#           包括 .xcstrings 字典语法与规范检测、Swift 源码中硬编码中文与英文句子审计、
#           键缺失（Missing Keys）与变量回溯分析、跨表一致性校验以及冗余键（Unused Keys）分析。
#

import os
import re
import sys
import json

# ==============================================================================
# MARK: - 全局配置区
# ==============================================================================

# 排除扫描的路径
EXCLUDE_DIRS = ['Localization/Catalogs', 'Tests', '.git', 'env', 'build', 'Frameworks', 'Resources']

# 允许包含非 ASCII 字符（汉字）的文件白名单（例如内置 Guide 生成、图标、AI 评测 Prompt 模板等）
ALLOW_NON_ASCII_FILES = {
    'IconTokens.swift',
    'DesignSystem+Icons.swift',
    'InitialNotebookGenerator.swift',
    'AIContentEnricher.swift',
    'RAGEvaluationService.swift',  # RAG 评价服务的中文硬编码 Prompt
    'ModelLabManager.swift'        # 大模型测试实验室的模拟推理输出数据源
}

# 匹配模式： " ... " 字符串字面量
STRING_PATTERN = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')

# 强类型检查模式：禁止在 UI / 业务层直接调用 .tr("...") 或 .trf("...", ...)
DIRECT_TR_PATTERN = re.compile(r'\.tr\("|\.trf\("')

# UI 组件关键字及常见赋值触发词（当所在行包含以下词且含有英文自然语言句子时，判定为 UI 硬编码）
UI_TRIGGERS = [
    'Text', '.navigationTitle', 'Label', 'Button', 'Placeholder', 'message:', 'title:', 'subtitle:',
    'prompt:', 'systemPrompt:', 'description:', 'errorMessage:', 'inputText', 'name:', 'hint:',
    'Label(', 'Button(', 'Alert(', 'ConfirmationDialog(', 'Toast(', 'LabelStyle(', 'Picker(', 'Toggle('
]

# 常见英文单词（用于启发式自然语言句子识别的权重匹配）
COMMON_ENGLISH_WORDS = {
    'you', 'are', 'your', 'the', 'this', 'that', 'with', 'from', 'into', 'please', 
    'error', 'failed', 'loading', 'success', 'not', 'found', 'cannot', 'only', 'expert', 
    'always', 'start', 'follow', 'using', 'based', 'provide', 'deep', 'insightful'
}

# 已知合法的 brand 驼峰命名，无需按 PascalCase 假翻译占位符拦截
KNOWN_PROPER_NAMES = {
    'VoiceOver', 'SiliconFlow', 'OpenAI', 'DeepSeek', 'MiniMax', 'Ollama',
    'Anthropic', 'macOS', 'iOS', 'iPadOS', 'watchOS', 'iPhone', 'iPad',
    'GitHub', 'GitLab', 'Bitbucket', 'ChatGPT', 'Claude', 'Gemini',
    'CoreML', 'Xcode', 'SwiftUI', 'UIKit', 'AppKit', 'WebKit',
    'CloudKit', 'HealthKit', 'MapKit', 'ARKit', 'RealityKit',
    'Keychain', 'Keynote', 'Numbers', 'Pages',
    'ZhiYu',  # 本应用名称
}

# 模块/文件前缀到 xcstrings 物理表名的强映射字典
DOMAIN_MAP = {
    'Localizable': 'Common',
    'Accessibility': 'Common',
    'Search': 'Common',
    'Editor': 'Knowledge',
    'Creation': 'Knowledge',
    'Vault': 'Knowledge',
    'Quiz': 'Knowledge',
    'KnowledgeBase': 'Knowledge',
    'Chat': 'AI',
    'Voice': 'AI',
    'AITasks': 'AI',
    'Graph': 'Insight',
    'Dashboard': 'Insight',
    'Auth': 'System',
    'Settings': 'System',
    'Lint': 'System',
    'Onboarding': 'System',
    'Coachmark': 'System',
    'Sync': 'Ingest',
    'Transfer': 'Ingest',
    'Collaboration': 'Plugin',
    'Watch': 'Platform',
    'Widget': 'Platform',
    'Common': 'Common',
    'Insight': 'Insight',
    'System': 'System',
    'AI': 'AI',
    'Knowledge': 'Knowledge',
    'Ingest': 'Ingest',
    'Plugin': 'Plugin',
    'Platform': 'Platform',
}

# 本地化 Key 命名空间允许的前缀集合
ALLOWED_KEY_PREFIXES = {
    'common', 'settings', 'auth', 'chat', 'ingest', 'weekly', 'report', 
    'insight', 'medal', 'tooltip', 'coachmark', 'dashboard', 'evaluation', 
    'action', 'log', 'logAction', 'menu', 'misc', 'sync', 'transfer', 
    'collaboration', 'error', 'tab', 'unit', 'preview', 'sidebar', 'weeklyReport',
    'pkm', 'widget', 'watch', 'platform', 'model_manager'
}


# ==============================================================================
# MARK: - 基础文本分析工具库 (TextUtil)
# ==============================================================================

class TextUtil:
    """提供本地化静态审计所需的文本启发式检测分析能力。"""

    @staticmethod
    def is_chinese(text):
        """
        判断字符串中是否包含 CJK 统一汉字。
        
        :param text: 待分析字符串
        :return: 包含汉字则返回 True，否则返回 False
        """
        if not text:
            return False
        return any('\u4e00' <= c <= '\u9fff' for c in text)

    @staticmethod
    def is_natural_language_sentence(text):
        """
        启发式算法：检测字符串是否为英文自然语言句子（非代码变量名、非文件路径）。
        
        :param text: 待分析字符串
        :return: 符合英文句子特征则返回 True
        """
        if not text or len(text) < 4:
            return False
        words = [w.lower().strip('.,!?()[]{}') for w in text.split()]
        if len(words) > 1:
            if any(w in COMMON_ENGLISH_WORDS for w in words):
                return True
            if re.search(r'[a-z] [a-z]', text, re.I):
                return True
        return False

    @staticmethod
    def is_compound_pascal_case(text):
        """
        分析检测字符串是否为 PascalCase/camelCase 复合词（通常是翻译未填写的代码占位符）。
        
        :param text: 待分析字符串
        :return: 符合占位符特征返回 True
        """
        if not text or ' ' in text:
            return False
        if not re.match(r'^[a-zA-Z]+$', text):
            return False
        if not re.search(r'[a-z][A-Z]|[A-Z]{2,}[a-z]', text):
            return False
        if len(text) <= 4:
            return False
        if text in KNOWN_PROPER_NAMES:
            return False
        words = [w for w in re.split(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', text) if w]
        return len(words) >= 2

    @staticmethod
    def is_view_file(file_path):
        """
        判断文件是否为 SwiftUI 视图或表现层文件。
        
        :param file_path: 文件路径
        :return: 属于表现层文件返回 True
        """
        path_lower = file_path.lower()
        return '/view/' in path_lower or '/views/' in path_lower or file_path.endswith('View.swift')


# ==============================================================================
# MARK: - Catalog 字典审计器 (XCStringsAuditor)
# ==============================================================================

class XCStringsAuditor:
    """负责解析和验证 Sources/Localization/Catalogs 目录下的所有 .xcstrings 字典合规性。"""

    def __init__(self, catalogs_dir='Sources/Localization/Catalogs'):
        self.catalogs_dir = catalogs_dir

    def audit(self):
        """
        执行 Catalog 全量审计。
        
        :return: 异常列表，元素为 (file, key, message, severity)
        """
        if not os.path.exists(self.catalogs_dir):
            return []

        files = [f for f in os.listdir(self.catalogs_dir) if f.endswith('.xcstrings')]
        issues = []

        for file in files:
            path = os.path.join(self.catalogs_dir, file)
            with open(path, 'r', encoding='utf-8') as f:
                try:
                    data = json.load(f)
                except Exception as e:
                    issues.append((file, "ALL", f"JSON parsing failed: {e}", "CRITICAL"))
                    continue

            strings = data.get('strings', {})
            for key, value in strings.items():
                locs = value.get('localizations', {})
                en_loc = locs.get('en', {}).get('stringUnit', {})
                zh_loc = locs.get('zh-Hans', {}).get('stringUnit', {})

                en_val = en_loc.get('value', '')
                zh_val = zh_loc.get('value', '')
                zh_state = zh_loc.get('state', '')

                en_trimmed = en_val.strip()
                zh_trimmed = zh_val.strip()

                def is_self_value_exempt(k, v):
                    if v.startswith('%'): return True
                    if v.startswith('http'): return True
                    if v in ('sk-...',): return True
                    if TextUtil.is_chinese(k): return True
                    return False

                if en_trimmed and '.' in key and en_trimmed == key and not is_self_value_exempt(key, en_trimmed):
                    issues.append((file, key, f'English value matches key itself: "{en_trimmed}" (unfilled placeholder)', "ERROR"))
                if zh_trimmed and '.' in key and zh_trimmed == key and not is_self_value_exempt(key, zh_trimmed):
                    issues.append((file, key, f'zh-Hans value matches key itself: "{zh_trimmed}" (unfilled placeholder)', "ERROR"))

                key_pattern = re.compile(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){2,}$')
                if key_pattern.match(en_trimmed):
                    issues.append((file, key, f'English value is formatted like a key: "{en_trimmed}"', "ERROR"))
                if key_pattern.match(zh_trimmed):
                    issues.append((file, key, f'zh-Hans value is formatted like a key: "{zh_trimmed}"', "ERROR"))

                if en_val != en_trimmed:
                    issues.append((file, key, f'English value has trailing/leading whitespace: "{repr(en_val)}"', "WARNING"))
                if zh_val != zh_trimmed:
                    issues.append((file, key, f'zh-Hans value has trailing/leading whitespace: "{repr(zh_val)}"', "WARNING"))

                if TextUtil.is_compound_pascal_case(en_val):
                    issues.append((file, key, f'English value is a compound PascalCase code placeholder: "{en_val}"', "ERROR"))

                if 'zh-Hans' not in locs:
                    if key.strip() and not re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', key):
                        issues.append((file, key, "Missing zh-Hans translation", "ERROR"))
                elif TextUtil.is_chinese(en_val) and not TextUtil.is_chinese(zh_val):
                    issues.append((file, key, f'English translation field contains Chinese characters: "{en_val}"', "ERROR"))
                elif en_trimmed == zh_trimmed and not TextUtil.is_chinese(en_trimmed) and en_trimmed != '':
                    if not re.match(r'^[0-9.%@\s\-\[\]\(\)]+$', en_trimmed):
                        if re.match(r'^llm\.(prompt\.(?!workshop\b|reset\b|expert\b)[a-zA-Z]+|ingest\.json)', key):
                            pass
                        elif TextUtil.is_natural_language_sentence(en_trimmed):
                            issues.append((file, key, f'Potential fake translation (zh is same as en sentence): "{en_trimmed}"', "ERROR"))
                        else:
                            issues.append((file, key, f'Identical zh/en detected: "{en_trimmed}"', "WARNING"))
                
                elif re.search(r'(\(zh\)|\[译\])$', zh_val.strip()):
                    issues.append((file, key, f'Unresolved auto-generated translation placeholder: "{zh_val}"', "ERROR"))

                elif zh_state and zh_state != 'translated':
                    issues.append((file, key, f'zh-Hans translation state is "{zh_state}"', "WARNING"))

                extraction_state = value.get('extractionState', '')
                if extraction_state == 'stale':
                    issues.append((file, key, "Key extractionState is 'stale' (will not compile)", "CRITICAL"))

                if not en_val:
                    issues.append((file, key, "English value is empty", "ERROR"))
                elif not en_val.strip():
                    issues.append((file, key, "English value is whitespace only", "WARNING"))
                if not zh_val:
                    issues.append((file, key, "zh-Hans value is empty", "ERROR"))
                elif not zh_val.strip():
                    issues.append((file, key, "zh-Hans value is whitespace only", "WARNING"))

        return issues


# ==============================================================================
# MARK: - Swift 源码硬编码审计器 (SourceCodeAuditor)
# ==============================================================================

class SourceCodeAuditor:
    """负责遍历和扫描 Swift 源码，发现违规的硬编码中文以及在 UI 语境下的英文句子。"""

    def __init__(self, root_dir='Sources', exclude_dirs=None):
        self.root_dir = root_dir
        self.exclude_dirs = exclude_dirs or EXCLUDE_DIRS
        
        logger_patterns = [
            r'\.(debug|info|warning|error|notice|trace|log)\s*\(',
            r'[Ll]ogger\.',
            r'[Ll]og\.',
            r'print\s*\(',
            r'NSLog\(',
            r'os_log\(',
            r'fatalError\(',
        ]
        self.logger_re = re.compile('|'.join(logger_patterns))

        self.exempt_strings = {
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
            "⌘",
            " [DatabaseManager] switchDatabase warning: Transactions draining timed out. Forcing connection close."
        }

    def check_file(self, file_path):
        """
        审计单个 Swift 文件的内容。
        
        :param file_path: 文件物理路径
        :return: 异常列表，元素为 (line_no, matched_text, message, severity)
        """
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            raw_content = f.read()

        def comment_replacer(match):
            return "\n" * match.group(0).count("\n")
        content = re.sub(r'/\*.*?\*/', comment_replacer, raw_content, flags=re.DOTALL)

        lines = []
        for line in content.split('\n'):
            if '//' in line:
                lines.append(line.split('//')[0])
            else:
                lines.append(line)

        issues = []
        filename = os.path.basename(file_path)
        is_allow_non_ascii = filename in ALLOW_NON_ASCII_FILES
        is_view = TextUtil.is_view_file(file_path)
        is_l10n_extension = 'Localization/Extensions' in file_path

        for i, line in enumerate(lines):
            line_no = i + 1

            if not is_l10n_extension and DIRECT_TR_PATTERN.search(line):
                issues.append((line_no, line.strip(), "Direct .tr()/.trf() call detected. MUST use L10n property.", "ERROR"))

            literals = STRING_PATTERN.findall(line)
            for s in literals:
                if s in self.exempt_strings or "Stress Test Page #" in s:
                    continue

                is_logger = bool(self.logger_re.search(line))

                if TextUtil.is_chinese(s):
                    if not is_allow_non_ascii:
                        severity = "WARNING" if is_logger else "ERROR"
                        issues.append((line_no, s, "Hardcoded non-ASCII string detected.", severity))
                else:
                    is_ui_trigger = any(trigger in line for trigger in UI_TRIGGERS)
                    is_sentence = TextUtil.is_natural_language_sentence(s)

                    if is_sentence:
                        if is_view and is_ui_trigger:
                            severity = "WARNING" if is_logger else "ERROR"
                            issues.append((line_no, s, "Hardcoded English sentence in UI context.", severity))
                        else:
                            issues.append((line_no, s, "Hardcoded English sentence detected in logic file.", "WARNING"))

        return issues

    def audit_all(self):
        """
        遍历 Sources 目录，执行全量源码硬编码审计。
        
        :return: dict: {file_path: [issues]}
        """
        all_source_issues = {}
        for root, dirs, files in os.walk(self.root_dir):
            dirs[:] = [d for d in dirs if d not in self.exclude_dirs]
            for file in files:
                if file.endswith('.swift'):
                    file_path = os.path.join(root, file)
                    issues = self.check_file(file_path)
                    if issues:
                        all_source_issues[file_path] = issues
        return all_source_issues


# ==============================================================================
# MARK: - 缺失键检测与回溯校验引擎 (MissingKeyDetector)
# ==============================================================================

class MissingKeyDetector:
    """分析扩展文件（Extensions）对底层 Localized.tr 的引用，发现未在 xcstrings 定义的键或跨表错配。"""

    def __init__(self, catalogs_dir='Sources/Localization/Catalogs', extensions_dir='Sources/Localization/Extensions'):
        self.catalogs_dir = catalogs_dir
        self.extensions_dir = extensions_dir
        self.domain_map = DOMAIN_MAP

    def detect(self):
        """
        执行缺失 Key 检查及变量回溯校验的总入口。
        
        :return: 异常列表，元素为 (file, key, message, severity)
        """
        all_keys, table_keys = self._build_xcstrings_index()
        missing = []

        # 1. 校验 L10n 扩展声明的物理表与键的对应关系
        self._check_extension_keys(all_keys, table_keys, missing)

        # 2. 检查非扩展模块中原生 L.tr() 异常使用情况
        self._check_raw_tr_calls(all_keys, missing)

        # 3. 校验非 Common 模块错误隐式解析成 Common table 的情况
        self._check_implicit_tr_mismatches(all_keys, table_keys, missing)

        # 4. 校验业务调用的 L10n.Module 对应的物理扩展文件是否完整
        self._check_l10n_modules_exist(missing)

        # 5. 扫描所有 Swift 文件，提取变量到 Key 的动态映射进行变量溯源
        var_to_keys = self._trace_variable_assignments(all_keys)

        # 6. 利用变量追踪校验带变量参数的 L10n.Module.tr() 跨表一致性
        self._check_l10n_tr_calls_with_vars(all_keys, table_keys, var_to_keys, missing)

        # 7. 全局静态字面量硬编码 Key 命名审计
        self._check_global_key_candidates(all_keys, missing)

        return missing

    def _build_xcstrings_index(self):
        """
        构建所有 xcstrings 键及其所属的物理表索引。
        
        :return: (all_keys, table_keys)
        """
        all_keys = set()
        table_keys = {}
        for file in os.listdir(self.catalogs_dir):
            if file.endswith('.xcstrings'):
                table = file.replace('.xcstrings', '')
                path = os.path.join(self.catalogs_dir, file)
                with open(path, 'r', encoding='utf-8') as f:
                    try:
                        data = json.load(f)
                        strings = data.get('strings', {})
                        all_keys.update(strings.keys())
                        table_keys[table] = set(strings.keys())
                    except Exception:
                        continue
        return all_keys, table_keys

    def _check_extension_keys(self, all_keys, table_keys, missing):
        """
        检测本地化 Extension 中硬编码 tr(...) 调用的键是否缺失或跨表错配。
        """
        table_pattern = re.compile(r'static (?:let t|let tableName)\s*=\s*"([^"]+)"')
        tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')
        tr_func_pattern = re.compile(r'trf?\(\s*"([^"]+)"')
        l_tr_pattern = re.compile(r'L\.trf?\(\s*"([^"]+)"')

        if not os.path.exists(self.extensions_dir):
            return

        for file in os.listdir(self.extensions_dir):
            if not file.endswith('.swift'):
                continue
            path = os.path.join(self.extensions_dir, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            tables = table_pattern.findall(content)
            if not tables:
                continue
            declared_table = tables[0]

            keys = set(tr_pattern.findall(content) + tr_func_pattern.findall(content) + l_tr_pattern.findall(content))
            for key in keys:
                if key not in all_keys:
                    missing.append((path, key, f"Key used in L10n extension but missing from ALL .xcstrings files", "ERROR"))
                elif declared_table in table_keys:
                    if key not in table_keys[declared_table]:
                        actual_files = [t for t, ks in table_keys.items() if key in ks]
                        missing.append((path, key, f"Table mismatch: key in extension (table=\"{declared_table}\") but key resides in {actual_files}", "ERROR"))

    def _check_raw_tr_calls(self, all_keys, missing):
        """
        扫描非 Extension 文件的 tr() 硬编码调用（如 Watch 端）。
        """
        l_tr_pattern = re.compile(r'L\.trf?\(\s*"([^"]+)"')
        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.')]
            for f in files:
                if f.endswith('.swift') and 'Extensions' not in root:
                    path = os.path.join(root, f)
                    with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                        content = fh.read()
                    for key in set(l_tr_pattern.findall(content)):
                        if key not in all_keys:
                            missing.append((path, key, "L.tr() key used in source code but missing from ALL .xcstrings", "ERROR"))

    def _check_implicit_tr_mismatches(self, all_keys, table_keys, missing):
        """
        校验非 Common 模块对 Localized.tr() 的隐式错误调用（导致表解析降级丢失）。
        """
        table_pattern = re.compile(r'static (?:let t|let tableName)\s*=\s*"([^"]+)"')
        tr_pattern = re.compile(r'Localized\.trf?\(\s*"([^"]+)"')

        for file in os.listdir(self.extensions_dir):
            if not file.endswith('.swift'): continue
            path = os.path.join(self.extensions_dir, file)
            with open(path, 'r', encoding='utf-8') as fh:
                content = fh.read()
            tables = table_pattern.findall(content)
            declared_table = tables[0] if tables else "Common"
            if declared_table == "Common": continue
            for key in set(tr_pattern.findall(content)):
                if key in all_keys and key not in table_keys.get(declared_table, set()):
                    actual = [t for t, ks in table_keys.items() if key in ks]
                    if declared_table not in actual:
                        mod = file.replace('L10n+', '').replace('.swift', '')
                        missing.append((path, key, f"Implicit Localized.tr() in L10n+{mod} (declared table is {declared_table}) but key is only in {actual}", "ERROR"))

    def _check_l10n_modules_exist(self, missing):
        """
        验证调用的 L10n.Module.* 语法是否对应真实的扩展文件。
        """
        l10n_module_pattern = re.compile(r'L10n\.([A-Z][a-zA-Z]*)\.')
        existing_modules = set()
        l10n_decl_pattern = re.compile(r'(?:public\s+)?(?:struct|enum|class)\s+([A-Z][a-zA-Z0-9_]*)\s*(?::|{)')
        for f in os.listdir(self.extensions_dir):
            if f.startswith('L10n+') and f.endswith('.swift'):
                existing_modules.add(f.replace('L10n+', '').replace('.swift', ''))
                with open(os.path.join(self.extensions_dir, f), 'r', encoding='utf-8') as fh:
                    content = fh.read()
                for mod in l10n_decl_pattern.findall(content):
                    existing_modules.add(mod)

        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in ('.git', 'Localization') and not d.startswith('.')]
            for f in files:
                if not f.endswith('.swift'): continue
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                for module in set(l10n_module_pattern.findall(content)):
                    if module not in existing_modules:
                        missing.append((path, module, f"L10n.{module}.* referenced in code but extension structure not found", "ERROR"))

    def _trace_variable_assignments(self, all_keys):
        """
        变量回溯追踪：扫描 Swift 源码提取变量赋本地化 key 的对应关联。
        """
        var_to_keys = {}
        var_assign_pattern = re.compile(r'\b([a-zA-Z0-9_]+)\b\s*[:=]\s*"([a-z0-9_]+(?:\.[a-z0-9_.-]+)+)"')

        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in ('.git', 'Localization') and not d.startswith('.')]
            for f in files:
                if not f.endswith('.swift'): continue
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                    
                content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                lines = [line.split('//')[0] if '//' in line else line for line in content.split('\n')]
                
                container_pattern = re.compile(r'\b(?:struct|class|enum)\s+([A-Z]\w*)')
                current_container = None
                
                for line in lines:
                    container_match = container_pattern.search(line)
                    if container_match:
                        current_container = container_match.group(1)
                        
                    for var_name, loc_key in var_assign_pattern.findall(line):
                        if '/' in loc_key or loc_key.startswith('http') or ' ' in loc_key:
                            continue
                        if loc_key in all_keys:
                            if var_name not in var_to_keys:
                                var_to_keys[var_name] = set()
                            var_to_keys[var_name].add(loc_key)
                            
                            if current_container:
                                full_var = f"{current_container}.{var_name}"
                                if full_var not in var_to_keys:
                                    var_to_keys[full_var] = set()
                                var_to_keys[full_var].add(loc_key)
        return var_to_keys

    def _check_l10n_tr_calls_with_vars(self, all_keys, table_keys, var_to_keys, missing):
        """
        校验含有变量回溯的 L10n.Module.tr() 的跨表错位。
        """
        l10n_tr_call_pattern = re.compile(r'L10n\.([A-Z][a-zA-Z]*)\.trf?\(\s*([^),]+)\s*')
        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in ('.git', 'Localization') and not d.startswith('.')]
            for f in files:
                if not f.endswith('.swift') or 'Extensions' in root: continue
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    lines = fh.readlines()
                    
                clean_lines = [line.split('//')[0] if '//' in line else line for line in lines]
                content_str = ''.join(clean_lines)
                
                for line in clean_lines:
                    for module, param in l10n_tr_call_pattern.findall(line):
                        param = param.strip()
                        target_table = self.domain_map.get(module)
                        if not target_table:
                            continue
                            
                        resolved_keys = set()
                        str_match = re.match(r'^"([^"]+)"$', param)
                        if str_match:
                            resolved_keys.add(str_match.group(1))
                        else:
                            var_id = param.split('.')[-1].strip()
                            var_prefix = param.split('.')[0].strip() if '.' in param else ""
                            
                            declared_type = None
                            if var_prefix:
                                type_decl_pattern = re.compile(rf'\b{var_prefix}\s*:\s*([A-Za-z0-9_.]+)')
                                type_matches = type_decl_pattern.findall(content_str)
                                if type_matches:
                                    declared_type = type_matches[0].split('.')[-1].strip()
                                    
                            type_key = f"{declared_type}.{var_id}" if declared_type else None
                            if type_key and type_key in var_to_keys:
                                resolved_keys.update(var_to_keys[type_key])
                            elif var_id in var_to_keys:
                                raw_keys = var_to_keys[var_id]
                                filtered_keys = set()
                                for rk in raw_keys:
                                    if module == 'Coachmark' and not (rk.startswith('tooltip.') or rk.startswith('coachmark.')):
                                        continue
                                    if module == 'Insight' and not (rk.startswith('medal.') or rk.startswith('weekly.') or rk.startswith('report.') or rk.startswith('insight.')):
                                        continue
                                    if module == 'Settings' and not rk.startswith('settings.'):
                                        continue
                                    filtered_keys.add(rk)
                                resolved_keys.update(filtered_keys)
                                
                        for rkey in resolved_keys:
                            if rkey not in all_keys:
                                continue
                                
                            actual_tables = [t for t, ks in table_keys.items() if rkey in ks]
                            if target_table not in actual_tables and 'Common' not in actual_tables:
                                missing.append((path, rkey,
                                    f"Table mismatch: L10n.{module}.tr({param}) resolves to table '{target_table}', "
                                    f"but key '{rkey}' only exists in {actual_tables}", "ERROR"))

    def _check_global_key_candidates(self, all_keys, missing):
        """
        全局静态字面量键值缺失检查（匹配前缀白名单）。
        """
        key_candidate_pattern = re.compile(r'"([a-z][a-z0-9_-]*(?:\.[a-z0-9_.-]+)+)"')
        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.')]
            for f in files:
                if not f.endswith('.swift') or 'Extensions' in root: continue
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                content = '\n'.join([line.split('//')[0] if '//' in line else line for line in content.split('\n')])
                
                for key_candidate in key_candidate_pattern.findall(content):
                    parts = key_candidate.split('.')
                    if not parts or parts[0] not in ALLOWED_KEY_PREFIXES:
                        continue
                    if '/' in key_candidate or key_candidate.startswith('http') or ' ' in key_candidate:
                        continue
                    if any(key_candidate.endswith(ext) for ext in ('.swift', '.json', '.js', '.css', '.png', '.jpg', '.jpeg', '.txt', '.db', '.zip', '.html', '.md')):
                        continue
                    if any(domain_term in key_candidate for domain_term in ('com.', 'org.', 'net.', '.com', '.org', '.net', '.io')):
                        continue
                    if key_candidate.startswith('auth.thirdparty.'):
                        continue

                    if key_candidate not in all_keys:
                        missing.append((path, key_candidate, f"Hardcoded key '{key_candidate}' detected in code but missing from catalogs", "ERROR"))


# ==============================================================================
# MARK: - 跨文件同键值冲突检测 (CrossFileInconsistencyDetector)
# ==============================================================================

class CrossFileInconsistencyDetector:
    """分析同一 Key 存在于多个 xcstrings 中，但中/英文定义不一致的情形。"""

    def __init__(self, catalogs_dir='Sources/Localization/Catalogs'):
        self.catalogs_dir = catalogs_dir

    def detect(self):
        """
        检测跨表不一致性。
        
        :return: 异常列表，元素为 (key, file_val_map, message, severity)
        """
        key_sources = {}
        for file in os.listdir(self.catalogs_dir):
            if not file.endswith('.xcstrings'):
                continue
            path = os.path.join(self.catalogs_dir, file)
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
            
            zh_values = {f: v[0] for f, v in files.items()}
            if len(set(zh_values.values())) > 1:
                issues.append((key, zh_values, f"Cross-file mismatch: key '{key}' has DIFFERENT zh-Hans values across files", "WARNING"))
                
            en_values = {f: v[1] for f, v in files.items()}
            if len(set(en_values.values())) > 1:
                issues.append((key, en_values, f"Cross-file mismatch: key '{key}' has DIFFERENT en values across files", "WARNING"))
                
        return issues


# ==============================================================================
# MARK: - 冗余键审计器 (ObsoleteKeyDetector)
# ==============================================================================

class ObsoleteKeyDetector:
    """分析 Catalog 中定义了，但在全源码及扩展中无任何引用的冗余 Unused Key。"""

    def __init__(self, catalogs_dir='Sources/Localization/Catalogs', extensions_dir='Sources/Localization/Extensions'):
        self.catalogs_dir = catalogs_dir
        self.extensions_dir = extensions_dir

    def detect(self):
        """
        分析找出冗余 Key 并报警。
        
        :return: 异常列表，元素为 (file, key, message, severity)
        """
        key_to_tables = {}
        all_keys_with_table = {}
        
        for file in os.listdir(self.catalogs_dir):
            if file.endswith('.xcstrings'):
                table = file.replace('.xcstrings', '')
                with open(os.path.join(self.catalogs_dir, file), 'r', encoding='utf-8') as f:
                    try:
                        data = json.load(f)
                    except Exception:
                        continue
                    strings = data.get('strings', {})
                    for key in strings.keys():
                        if key not in key_to_tables:
                            key_to_tables[key] = set()
                        key_to_tables[key].add(table)
                        all_keys_with_table[f"{key}@{table}"] = (key, file)

        used_keys_with_table = set()
        table_pattern = re.compile(r'static (?:let t|let tableName)\s*=\s*"([^"]+)"')
        
        if os.path.exists(self.extensions_dir):
            for file in os.listdir(self.extensions_dir):
                if not file.endswith('.swift'):
                    continue
                path = os.path.join(self.extensions_dir, file)
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                tables = table_pattern.findall(content)
                declared_table = tables[0] if tables else "Common"
                
                content_clean = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                lines = [line.split('//')[0] for line in content_clean.split('\n')]
                
                for line in lines:
                    literals = STRING_PATTERN.findall(line)
                    for lit in literals:
                        if lit in key_to_tables:
                            table_match = re.search(r'table\s*:\s*"([^"]+)"', line)
                            if table_match:
                                used_keys_with_table.add(f"{lit}@{table_match.group(1)}")
                            else:
                                used_keys_with_table.add(f"{lit}@{declared_table}")

        for root, dirs, files in os.walk('Sources'):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.')]
            for f in files:
                if not f.endswith('.swift') or 'Extensions' in root:
                    continue
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    content = fh.read()
                
                content_clean = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                lines = [line.split('//')[0] for line in content_clean.split('\n')]
                
                for line in lines:
                    literals = STRING_PATTERN.findall(line)
                    for lit in literals:
                        if lit in key_to_tables:
                            table_match = re.search(r'table\s*:\s*"([^"]+)"', line)
                            if table_match:
                                used_keys_with_table.add(f"{lit}@{table_match.group(1)}")
                            else:
                                for t in key_to_tables[lit]:
                                    used_keys_with_table.add(f"{lit}@{t}")

        dynamic_prefixes = (
            'plugin.perm.',
            'ingest.status.',
            'aitask.',
            'ondevice.',
            'icloud.',
            'llm.',
            'weekly.aiAnalysis'
        )
        
        unused_issues = []
        for ref, (key, file) in all_keys_with_table.items():
            if ref in used_keys_with_table:
                continue
            if any(key.startswith(pre) for pre in dynamic_prefixes):
                continue
            if not key.strip():
                continue
                
            unused_issues.append((file, key, f"Unused localization key '{key}' found in {file} (no references in source code)", "WARNING"))
            
        return unused_issues


# ==============================================================================
# MARK: - 报告输出与执行入口 (main)
# ==============================================================================

def main():
    """本地化守卫网关的执行总入口。"""
    
    code_auditor = SourceCodeAuditor()
    catalog_auditor = XCStringsAuditor()
    missing_detector = MissingKeyDetector()
    inconsistency_detector = CrossFileInconsistencyDetector()
    obsolete_detector = ObsoleteKeyDetector()

    all_source_issues = code_auditor.audit_all()
    xcstrings_issues = catalog_auditor.audit()
    missing_key_issues = missing_detector.detect()
    cross_file_issues = inconsistency_detector.detect()
    unused_key_issues = obsolete_detector.detect()

    has_critical = False

    if all_source_issues:
        print("❌ [L10n Audit] Source Code Violations:")
        for file_path, issues in sorted(all_source_issues.items()):
            print(f"\n📂 {file_path}")
            for line_no, content, msg, level in issues:
                icon = "🚨" if level == "ERROR" or level == "CRITICAL" else "⚠️"
                if level == "ERROR" or level == "CRITICAL":
                    has_critical = True
                print(f"  L{line_no}: {icon} [{msg}] \"{content}\"")

    if xcstrings_issues:
        print("\n❌ [L10n Audit] .xcstrings Catalog Issues:")
        current_file = ""
        for file, key, msg, level in xcstrings_issues:
            if file != current_file:
                print(f"\n📂 {file}")
                current_file = file
            icon = "🚨" if level == "ERROR" or level == "CRITICAL" else "⚠️"
            if level == "ERROR" or level == "CRITICAL":
                has_critical = True
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
            icon = "🚨" if level == "ERROR" else "⚠️"
            if level == "ERROR":
                has_critical = True
            print(f"  Key: \"{key}\" - {icon} [{level}] {msg}")
            for file, val in sources.items():
                print(f"    {file}: \"{val}\"")

    if unused_key_issues:
        print("\n⚠️ [L10n Audit] Unused Keys in Catalogs:")
        for file, key, msg, level in sorted(unused_key_issues):
            print(f"  Key: \"{key}\" - ⚠️ [{level}] {msg}")

    if not all_source_issues and not xcstrings_issues and not missing_key_issues and not cross_file_issues and not unused_key_issues:
        print("\n✅ [L10n Audit] Localization quality standards met.")
        sys.exit(0)
    
    if has_critical:
        print("\n[L10n Audit] CRITICAL VIOLATIONS. Build blocked.")
        sys.exit(1)
    else:
        print("\n[L10n Audit] Suggestions for cleanup found. Build permitted.")
        sys.exit(0)


if __name__ == '__main__':
    main()
