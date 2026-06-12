#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: check_docs_integrity.py
# 脚本功能: 静态审计项目文档的完整性、死链、大小写敏感一致性及陈旧废弃内容。
#           能在 APFS (大小写不敏感) 系统上严格校验磁盘文件字母大小写，提前预防 Linux CI 死链。
# 调用方式:
#   python3 Tools/Gatekeeper/check_docs_integrity.py
# ==============================================================================

import os
import re
import sys

# ── 1. 静态配置与关键字定义 ──────────────────────────────────────────
CLEANUP_KEYWORDS = [
    "TODO: 待清理",
    "TODO: 待删除",
    "DEPRECATED_FLAG",
    "OBSOLETE_TEMP"
]

CORE_INDEX_FILES = [
    "AGENTS.md",
    "GEMINI.md"
]

# 豁免死链审计的模板或开发用文档目录/文件
EXCLUDE_DOC_FILES = [
    "Tools/Plugins/README_TEMPLATE.md",
    "Tools/Plugins/PLUGIN_DEVELOPMENT_GUIDE.md"
]

# 链接提取正则
LINK_REGEX = re.compile(r'!?\[.*?\]\((.*?)\)')
REF_LINK_REGEX = re.compile(r'^\[.*?\]:\s*([^\s#]+)')

# ── 2. 核心辅助函数 ──────────────────────────────────────────────
def clean_relative_link(base_dir, relative_path):
    """
    清洗链接，返回标准化的相对路径，若为外部绝对路径则直接做物理存在性检测。
    """
    if relative_path.startswith("file://"):
        cleaned_path = relative_path.replace("file://", "")
        if cleaned_path.startswith(base_dir):
            relative_path = os.path.relpath(cleaned_path, base_dir)
        else:
            return cleaned_path, os.path.exists(cleaned_path)
            
    if "#" in relative_path:
        relative_path = relative_path.split("#")[0]
        
    return relative_path, None

def check_case_sensitive_exists(file_dir, relative_path, workspace):
    """
    在任何文件系统上，严格校验相对路径的大小写是否与磁盘实际物理文件名完全匹配。
    """
    # 豁免 IDE 工具历史记录及 superpowers 相关的超链接
    if "superpowers" in relative_path:
        return True

    if relative_path.startswith("file://"):
        rel_path, quick_check = clean_relative_link(workspace, relative_path)
        if quick_check is not None:
            return quick_check
        base_dir = workspace
    elif relative_path.startswith("/"):
        rel_path = relative_path.lstrip("/")
        base_dir = workspace
    else:
        rel_path = relative_path
        base_dir = file_dir

    if "#" in rel_path:
        rel_path = rel_path.split("#")[0]

    if not rel_path:
        return True

    parts = [p for p in rel_path.replace("\\", "/").split("/") if p]
    current = base_dir

    for part in parts:
        if part == ".":
            continue
        if part == "..":
            current = os.path.dirname(current)
            continue

        if not os.path.exists(current) or not os.path.isdir(current):
            return False

        try:
            children = os.listdir(current)
        except OSError:
            return False

        if part in children:
            current = os.path.join(current, part)
        else:
            return False
    return True

def parse_markdown_links(file_path):
    """
    解析 Markdown 文件，返回包含的所有本地路径链接及行号。
    使用 errors="ignore" 容错非 UTF-8 编码的文件。
    """
    links = []
    cleanup_issues = []
    
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        for idx, line in enumerate(f, 1):
            for keyword in CLEANUP_KEYWORDS:
                if keyword in line:
                    cleanup_issues.append((idx, keyword))

            for match in LINK_REGEX.findall(line):
                links.append((idx, match))
                
            ref_match = REF_LINK_REGEX.match(line.strip())
            if ref_match:
                links.append((idx, ref_match.group(1)))
                
    return links, cleanup_issues

def find_all_markdown_files(workspace):
    """
    遍历获取项目下的所有 Markdown 文件。排除以 . 开头的隐藏目录及缓存依赖项。
    """
    md_files = []
    for root, _, files in os.walk(workspace):
        parts = root.split(os.sep)
        if any(p.startswith(".") and p != "." and p != ".." for p in parts):
            continue
            
        if any(p in root for p in ["build", "DerivedData", ".cache", "node_modules"]):
            continue
            
        for file in files:
            if file.endswith(".md"):
                md_files.append(os.path.join(root, file))
    return md_files

# ── 3. 拆分校验模块以降低认知复杂度 ──────────────────────────────
def audit_single_file(workspace, file_path):
    """
    审计单个文件的死链接和清理标识。
    """
    rel_file_path = os.path.relpath(file_path, workspace)
    
    # 检测是否为豁免文件
    normalized_rel_path = rel_file_path.replace("\\", "/")
    if any(ex in normalized_rel_path for ex in EXCLUDE_DOC_FILES):
        return False

    links, cleanup_issues = parse_markdown_links(file_path)
    file_has_error = False

    if cleanup_issues:
        print(f"❌ 废弃清理检查失败: 文件 [{rel_file_path}] 中包含需清理的陈旧标识:")
        for line_no, kw in cleanup_issues:
            print(f"  - 第 {line_no} 行: 发现残留关键字 '{kw}'")
        file_has_error = True

    for line_no, link in links:
        if link.startswith(("http://", "https://", "mailto:")) or link.startswith("#"):
            continue

        file_dir = os.path.dirname(file_path)
        is_valid = check_case_sensitive_exists(file_dir, link, workspace)
        if not is_valid:
            print(f"❌ 链接死链或大小写不匹配: 文件 [{rel_file_path}] 第 {line_no} 行:")
            print(f"  - 引用链接: '{link}'")
            print(f"  - 原因: 文件不存在，或磁盘物理大小写与引用不匹配")
            file_has_error = True

    return file_has_error

def audit_core_indices(workspace):
    """
    校验核心索引文件引用的文件存在性。
    """
    index_has_error = False
    for index_file in CORE_INDEX_FILES:
        index_path = os.path.join(workspace, index_file)
        if not os.path.exists(index_path):
            continue
        
        links, _ = parse_markdown_links(index_path)
        for line_no, link in links:
            if link.endswith(".md") and not link.startswith(("http://", "https://")):
                is_valid = check_case_sensitive_exists(workspace, link, workspace)
                if not is_valid:
                    print(f"❌ 索引引用缺失: [{index_file}] 第 {line_no} 行引用的核心文档不存在:")
                    print(f"  - 核心文档路径: '{link}'")
                    index_has_error = True
    return index_has_error

# ── 4. 主入口流程 ──────────────────────────────────────────────
def main():
    workspace = os.getcwd()
    print("=== 开始文档完整性与死链健康度审计 ===")
    print(f"工作空间: {workspace}")

    md_files = find_all_markdown_files(workspace)
    print(f"共发现 {len(md_files)} 个 Markdown 文件进行审计。")

    has_error = False
    for file_path in md_files:
        if audit_single_file(workspace, file_path):
            has_error = True

    if audit_core_indices(workspace):
        has_error = True

    if has_error:
        print("=== ❌ 审计结束: 文档检查未通过，请处理上述报错 ===")
        sys.exit(1)
    else:
        print("=== ✓ 审计成功: 所有文档健康，大小写一致，无死链及陈旧内容 ===")
        sys.exit(0)

if __name__ == "__main__":
    main()
