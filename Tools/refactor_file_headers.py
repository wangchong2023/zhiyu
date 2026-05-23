#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  refactor_file_headers.py
#  ZhiYu
#
#  Created by Antigravity on 2026/05/23.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：Tools 开发者辅助工具
#  核心职责：自动扫描项目中的 Swift 文件，对缺失标准中文文件头的 Swift 文件进行智能推导并批量补齐。
#

import os
import re
import sys
from datetime import datetime

# 标准文件头模板
HEADER_TEMPLATE = """//
//  {file_name}
//  ZhiYu
//
//  Created by Antigravity on {date}.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：{level}
//  核心职责：{responsibility}
//
"""

def derive_level_and_responsibility(file_path):
    """
    根据文件的物理路径和文件名，自动推导其所属的系统层级与核心职责。
    """
    file_name = os.path.basename(file_path)
    dir_path = os.path.dirname(file_path)
    
    # 1. 推导系统层级
    level = "[L2] 业务功能层"  # 默认值
    if "Sources/App" in file_path:
        level = "[L3] 应用层"
    elif "Sources/Features" in file_path:
        level = "[L2] 业务功能层"
    elif "Sources/Domain" in file_path:
        level = "[L1.5] 领域层"
    elif "Sources/Infrastructure" in file_path:
        level = "[L1] 基础设施层"
    elif "Sources/Core/System" in file_path:
        level = "[L0.5] 系统集成层"
    elif "Sources/Core/Base" in file_path:
        level = "[L0] 底层基座层"
    elif "Sources/Shared" in file_path:
        level = "[Shared] 共享标准层"
    elif "Sources/Platforms" in file_path:
        level = "[Shared] 平台适配层"
    elif "Sources/Localization" in file_path:
        level = "[Shared] 本地化层"
    elif "Tests" in file_path:
        level = "[Shared] 测试层"
        
    # 2. 启发式推导核心职责
    responsibility = "提供相关业务支持"
    name_without_ext = os.path.splitext(file_name)[0]
    
    if name_without_ext.startswith("L10n+"):
        sub_module = name_without_ext.replace("L10n+", "")
        responsibility = f"为 {sub_module} 模块提供本地化强类型字符串的访问扩展。"
    elif name_without_ext == "L10n":
        responsibility = "定义统一的本地化加载与管理中心。"
    elif name_without_ext.endswith("Protocol"):
        responsibility = f"定义 {name_without_ext.replace('Protocol', '')} 模块的抽象契约接口。"
    elif name_without_ext.endswith("Service"):
        responsibility = f"实现 {name_without_ext.replace('Service', '')} 模块的核心业务逻辑服务。"
    elif name_without_ext.endswith("View"):
        responsibility = f"构建 {name_without_ext.replace('View', '')} 界面的 UI 视图层组件。"
    elif name_without_ext.endswith("ViewModel"):
        responsibility = f"管理 {name_without_ext.replace('ViewModel', '')} 视图的状态绑定与数据交互逻辑。"
    elif name_without_ext.endswith("Coordinator"):
        responsibility = f"负责 {name_without_ext.replace('Coordinator', '')} 业务流的导航路由与协作管理。"
    elif name_without_ext.endswith("Tests"):
        responsibility = f"针对 {name_without_ext.replace('Tests', '')} 开展自动化单元测试验证。"
    elif "Mock" in name_without_ext:
        responsibility = f"为单元测试提供 {name_without_ext} 仿真服务占位。"
    else:
        # 基于目录名做一些默认推导
        last_dir = os.path.basename(dir_path)
        responsibility = f"属于 {last_dir} 模块，提供相关的结构体或工具支撑。"
        
    return level, responsibility

def check_and_fix_file(file_path, dry_run=False):
    """
    检查 Swift 文件头，若缺失或非标准，则进行修复。
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    prefix_lines = content.split('\n')[:12]
    prefix_block = "\n".join(prefix_lines)
    
    # 匹配条件：如果文件开头前 12 行中已经包含了带方括号的标准系统层级注释，则判定为已合规
    has_bracketed_level = bool(re.search(r"系统层级：\s*\[(L0|L0\.5|L1|L1\.5|L2|L3|Shared)\]", prefix_block))
    
    if has_bracketed_level:
        return False, "Already Standard"
            
    # 需要重写文件头
    file_name = os.path.basename(file_path)
    level, responsibility = derive_level_and_responsibility(file_path)
    date_str = datetime.now().strftime("%Y/%m/%d")
    
    new_header = HEADER_TEMPLATE.format(
        file_name=file_name,
        date=date_str,
        level=level,
        responsibility=responsibility
    )
    
    # 清理旧的头部注释块。如果文件开头有连续的 // 注释或空白行，我们将其抹除，代之以全新标准头
    lines = content.split('\n')
    start_idx = 0
    while start_idx < len(lines):
        line = lines[start_idx].strip()
        if line.startswith("//") or line == "":
            start_idx += 1
        else:
            break
            
    remaining_content = "\n".join(lines[start_idx:])
    final_content = new_header + remaining_content
    
    if not dry_run:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(final_content)
            
    return True, f"Level: {level} | Resp: {responsibility}"

def main():
    workspace = "/Users/constantine/Documents/work/code/projects/ZhiYu"
    sources_dir = os.path.join(workspace, "Sources")
    tests_dir = os.path.join(workspace, "Tests")
    
    dry_run = "--dry-run" in sys.argv
    check_mode = "--check" in sys.argv
    
    print(f"🔍 启动项目文件头检查治理... (Mode: {'Check' if check_mode else ('Dry Run' if dry_run else 'Execution')})")
    print(f"📂 扫描路径: {sources_dir} & {tests_dir}")
    
    fixed_count = 0
    total_count = 0
    
    for root, dirs, files in os.walk(sources_dir):
        # 排除编译缓存等隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.swift'):
                total_count += 1
                file_path = os.path.join(root, file)
                modified, detail = check_and_fix_file(file_path, dry_run=(dry_run or check_mode))
                if modified:
                    fixed_count += 1
                    relative_path = os.path.relpath(file_path, workspace)
                    print(f"📝 [{'CHECK-FAILED' if check_mode else ('DRY' if dry_run else 'FIXED')}] {relative_path} -> {detail}")
                    
    for root, dirs, files in os.walk(tests_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.swift'):
                total_count += 1
                file_path = os.path.join(root, file)
                modified, detail = check_and_fix_file(file_path, dry_run=(dry_run or check_mode))
                if modified:
                    fixed_count += 1
                    relative_path = os.path.relpath(file_path, workspace)
                    print(f"📝 [{'CHECK-FAILED' if check_mode else ('DRY' if dry_run else 'FIXED')}] {relative_path} -> {detail}")
                    
    print("------------------------------------------------------------------")
    if check_mode:
        print(f"📊 检查完毕! 共有 {fixed_count} 个文件的文件头不符合中文标准规范。")
        if fixed_count > 0:
            print("❌ 错误: 发现不合规文件头。请运行 Tools/refactor_file_headers.py 自动治理补齐。")
            sys.exit(1)
        else:
            print("✅ 完美! 全量 Swift 文件头注释均符合中文规范。")
            sys.exit(0)
    else:
        print(f"📊 治理完毕! 共扫描 Swift 文件: {total_count} 个，修复/更新文件头: {fixed_count} 个。")

if __name__ == "__main__":
    main()
