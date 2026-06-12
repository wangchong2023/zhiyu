#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: check_configs_integrity.py
# 脚本功能: 静态审计项目中的 Python 脚本（语法编译）、YAML 配置文件（格式合规）及垃圾文件残留。
# 调用方式:
#   python3 Tools/Gatekeeper/check_configs_integrity.py
# ==============================================================================

import os
import py_compile
import re
import sys

# 尝试导入 PyYAML 模块以做强类型语法校验，若无则使用 Fallback 简易校验
try:
    import yaml
    HAVE_YAML = True
except ImportError:
    HAVE_YAML = False

# ── 1. 垃圾文件防错黑名单配置 ──────────────────────────────────────
DIRTY_SUFFIXES = (".tmp", ".bak", "xcuserdata")
DIRTY_NAMES = (".DS_Store", "Thumbs.db", ".gitleaks.toml.bak")
DIRTY_PATTERNS = [
    re.compile(r'^check_results.*\.txt$'),
    re.compile(r'^l10n_issues.*\.log$'),
    re.compile(r'^l10n_out\.txt$')
]

# 在根目录下不允许直接提交的非受控临时开发/重构 Python 脚本
ROOT_DIRTY_PY_SCRIPTS = [
    "fix_all.py",
    "fix_filterTags.py",
    "fix_l10n.py",
    "fix_l10n_errors.py",
    "fix_l10n_mismatches.py",
    "fix_magic_constants.py",
    "fix_p1.py",
    "fix_plugin_l10n.py",
    "fix_uicomponents.py",
    "replace_menu.py",
    "update_privacy.py",
    "update_strings.py",
    "update_strings2.py",
    "add_subtitles.py",
    "add_l10n_rag.py"
]

# ── 2. 核心校验函数 ──────────────────────────────────────────────
def check_python_files(workspace):
    """
    扫描 Tools 目录下所有 Python 文件，通过 py_compile 执行语法安全分析。
    """
    print("===> 开始校验 Python 脚本语法...")
    has_error = False
    py_files = []
    
    for root, _, files in os.walk(os.path.join(workspace, "Tools")):
        for file in files:
            if file.endswith(".py"):
                py_files.append(os.path.join(root, file))
                
    print(f"  发现 {len(py_files)} 个 Python 脚本文件。")
    
    for py_file in py_files:
        rel_path = os.path.relpath(py_file, workspace)
        try:
            py_compile.compile(py_file, doraise=True)
        except py_compile.PyCompileError as e:
            print(f"❌ Python 语法编译失败: [{rel_path}]")
            print(f"  - 详情: {e.msg}")
            has_error = True
            
    return not has_error

def audit_single_yaml_file(workspace, yml_file):
    """
    审计单个 YAML 文件的合法性。
    """
    rel_path = os.path.relpath(yml_file, workspace)
    
    if HAVE_YAML:
        try:
            with open(yml_file, "r", encoding="utf-8") as f:
                yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"❌ YAML 语法解析失败: [{rel_path}]")
            print(f"  - 解析器报错: {e}")
            return True
    else:
        try:
            with open(yml_file, "r", encoding="utf-8") as f:
                for line_idx, line in enumerate(f, 1):
                    if "\t" in line:
                        print(f"❌ YAML 规范校验失败: [{rel_path}] 第 {line_idx} 行包含制表符 (Tab)，YAML 只允许空格缩进！")
                        return True
        except Exception as e:
            print(f"❌ 配置文件读取失败: [{rel_path}] - {e}")
            return True
            
    return False

def check_yaml_files(workspace):
    """
    校验项目下的 project.yml 及 .woodpecker*.yml 配置文件的格式规范。
    """
    print("===> 开始校验 YAML/YML 配置文件结构...")
    has_error = False
    yaml_targets = []
    
    for file in os.listdir(workspace):
        if file.endswith((".yml", ".yaml")) and file != "project.yml":
            yaml_targets.append(os.path.join(workspace, file))
            
    proj_yml = os.path.join(workspace, "project.yml")
    if os.path.exists(proj_yml):
        yaml_targets.append(proj_yml)
        
    print(f"  发现 {len(yaml_targets)} 个配置文件需要校验。")
    
    for yml_file in yaml_targets:
        if audit_single_yaml_file(workspace, yml_file):
            has_error = True
                
    if not HAVE_YAML:
        print("  ⚠️ 提示: 本地环境未检测到 'pyyaml' 模块，已自动切换为制表符与格式防空健壮性 Fallback 校验。")
        
    return not has_error

def check_garbage_files(workspace):
    """
    遍历整个项目，扫描是否残存违规的临时文件、OS/IDE垃圾文件及无用开发脚本。
    """
    print("===> 开始扫描项目垃圾文件及残留临时配置...")
    has_error = False
    garbage_found = []

    for root, _, files in os.walk(workspace):
        if any(p in root for p in ["build", "DerivedData", ".cache", "node_modules", ".git"]):
            continue
            
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, workspace)
            
            if file in DIRTY_NAMES:
                garbage_found.append((rel_path, "操作系统/编辑器垃圾文件"))
                continue
                
            if file.endswith(DIRTY_SUFFIXES):
                garbage_found.append((rel_path, "临时缓存/本地私有配置"))
                continue
                
            for pattern in DIRTY_PATTERNS:
                if pattern.match(file):
                    garbage_found.append((rel_path, "开发分析过程残留临时文件"))
                    break
            
            if root == workspace and file in ROOT_DIRTY_PY_SCRIPTS:
                garbage_found.append((rel_path, "根目录下残留的临时开发重构脚本（请移入 Tools/ 目录或删除）"))

    if garbage_found:
        print("❌ 发现未受控的垃圾文件/临时残留脚本 (请在本地执行清理后再提交):")
        for path, reason in garbage_found:
            print(f"  - [{path}] : {reason}")
        has_error = True
    else:
        print("  ✓ 未发现垃圾文件及临时残留。")

    return not has_error

# ── 3. 主入口流程 ──────────────────────────────────────────────
def main():
    workspace = os.getcwd()
    print("=== 开始 Python 脚本与配置文件静态审计 ===")
    
    py_ok = check_python_files(workspace)
    yaml_ok = check_yaml_files(workspace)
    garbage_ok = check_garbage_files(workspace)
    
    if not py_ok or not yaml_ok or not garbage_ok:
        print("=== ❌ 审计结束: 脚本或配置文件检查未通过 ===")
        sys.exit(1)
    else:
        print("=== ✓ 审计成功: 脚本及文件格式全部合规 ===")
        sys.exit(0)

if __name__ == "__main__":
    main()
