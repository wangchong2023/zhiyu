#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  check_root_hygiene.py
#  ZhiYu
#
#  系统层级：[Tools/Gatekeeper] 守卫网关
#  核心职责：根目录卫生检查 — 临时文件清理 + 非预期文件/目录检测
#           遵循业界 Shift-Left 实践，在 CI 中阻断仓库污染。

import os
import sys

# ==============================================================================
# MARK: - 配置
# ==============================================================================

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# 根目录白名单：允许存在的文件与目录
EXPECTED_ROOT_ITEMS = {
    # 隐藏目录
    ".claude", ".codegraph", ".git", ".github", ".remember", ".superpowers",
    ".VSCodeCounter", ".woodpecker", ".workbuddy",
    # 配置文件
    ".DS_Store",          # macOS 系统文件（允许存在但应在 .gitignore 中）
    ".gitignore", ".swiftlint.yml", ".woodpecker.yml",
    # 项目文件
    "AGENTS.md", "CLAUDE.md", "GEMINI.md", "README.md",
    "LICENSE", "project.yml", "ZhiYu.code-workspace",
    # 主要目录
    "build", "Docs", "env", "Frameworks", "Sources", "Tests", "Tools",
    "ZhiYu.xcodeproj", "fastlane",
}

# 临时文件/垃圾文件后缀
TEMP_EXTENSIONS = {
    ".tmp", ".swp", ".swo", ".bak", ".orig", ".rej",
    ".DS_Store", "Thumbs.db", "~",
}

# 排除扫描的目录
EXCLUDE_DIRS = {".git", "build", "DerivedData", ".build", "Frameworks", "env", "__pycache__"}

# 临时目录模式
TEMP_DIR_PATTERNS = {".mypy_cache", ".pytest_cache", ".ruff_cache", "node_modules"}


def find_temp_files(root_dir: str) -> list[str]:
    """递归扫描项目中的临时/垃圾文件."""
    issues = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # 排除不需要扫描的目录
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]

        rel_dir = os.path.relpath(dirpath, root_dir)

        # 检查目录名是否为临时目录模式
        dir_basename = os.path.basename(dirpath)
        if dir_basename in TEMP_DIR_PATTERNS and rel_dir != ".":
            issues.append(f"[TEMP_DIR] 临时缓存目录: {rel_dir}/")

        for filename in filenames:
            _, ext = os.path.splitext(filename)
            if ext.lower() in TEMP_EXTENSIONS:
                # .DS_Store 在非根目录就是垃圾
                if filename == ".DS_Store" and rel_dir == ".":
                    continue  # 根目录 .DS_Store 已列入白名单
                filepath = os.path.join(rel_dir, filename) if rel_dir != "." else filename
                issues.append(f"[TEMP_FILE] 临时文件应删除: {filepath}")

            # 检查以 ~ 结尾的备份文件
            if filename.endswith("~"):
                filepath = os.path.join(rel_dir, filename) if rel_dir != "." else filename
                issues.append(f"[TEMP_FILE] 编辑器备份文件: {filepath}")

    return issues


def check_root_structure(root_dir: str) -> list[str]:
    """检查根目录是否只包含白名单中的条目."""
    issues = []
    try:
        items = set(os.listdir(root_dir))
    except OSError as e:
        return [f"[ERROR] 无法读取根目录: {e}"]

    unexpected = items - EXPECTED_ROOT_ITEMS
    if unexpected:
        for item in sorted(unexpected):
            item_path = os.path.join(root_dir, item)
            item_type = "目录" if os.path.isdir(item_path) else "文件"
            issues.append(
                f"[ROOT_VIOLATION] 根目录存在非预期{item_type}: '{item}' — "
                f"请清理或添加到 EXPECTED_ROOT_ITEMS 白名单"
            )

    # 额外检查：确保关键文件存在
    required_files = ["project.yml", "README.md", ".gitignore"]
    for f in required_files:
        if f not in items:
            issues.append(f"[MISSING] 根目录缺少关键文件: '{f}'")

    return issues


def main() -> int:
    print("=" * 60)
    print("🧹 根目录卫生检查 (Root Hygiene Check)")
    print("=" * 60)

    all_issues = []

    # 1. 临时文件扫描
    print("\n📁 扫描临时/垃圾文件...")
    temp_issues = find_temp_files(PROJECT_DIR)
    if temp_issues:
        all_issues.extend(temp_issues)
        for issue in temp_issues:
            print(f"  ❌ {issue}")
    else:
        print("  ✅ 未发现临时文件")

    # 2. 根目录结构检查
    print("\n📂 检查根目录文件结构...")
    root_issues = check_root_structure(PROJECT_DIR)
    if root_issues:
        all_issues.extend(root_issues)
        for issue in root_issues:
            print(f"  ❌ {issue}")
    else:
        print("  ✅ 根目录结构符合预期")

    # ── 结果 ──
    print("\n" + "=" * 60)
    if all_issues:
        print(f"❌ 发现 {len(all_issues)} 个问题，请修复后重新提交。")
        print("=" * 60)
        return 1
    else:
        print("✅ 根目录卫生检查全部通过！")
        print("=" * 60)
        return 0


if __name__ == "__main__":
    sys.exit(main())
