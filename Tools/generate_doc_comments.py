#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  generate_doc_comments.py
#  ZhiYu
#
#  Created by Antigravity on 2026/05/23.
#  Copyright © 2026 WangChong. All rights reserved.
#
#  系统层级：Tools 开发者辅助工具
#  核心职责：精准分析 Swift 代码，提取所有缺失 /// 中文文档注释的非私有 (internal/public) 函数并导出报告。
#

import os
import re

def is_private_func(line):
    """判断是否为私有函数"""
    # 匹配 private func 或 fileprivate func
    return "private func" in line or "fileprivate func" in line

def is_func_declaration(line):
    """判断是否为函数声明"""
    # 匹配含 func 的行，但要排除注释行
    stripped = line.strip()
    if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
        return False
    return "func " in line

def scan_missing_comments(workspace_dir):
    """
    扫描项目中所有 Swift 文件，寻找未写 /// 注释的非私有函数。
    """
    sources_dir = os.path.join(workspace_dir, "Sources")
    report = []
    total_funcs = 0
    missing_funcs = 0
    
    # 匹配函数声明的正则，捕获函数名
    func_pattern = re.compile(r'(?:public\s+|internal\s+|open\s+|@objc\s+|@MainActor\s+)*func\s+([a-zA-Z0-9_]+)\b')
    
    for root, dirs, files in os.walk(sources_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, workspace_dir)
                
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    
                for idx, line in enumerate(lines):
                    if is_func_declaration(line) and not is_private_func(line):
                        total_funcs += 1
                        
                        # 检查它的前几行是否有以 `///` 开始的行
                        has_doc_comment = False
                        
                        # 向上回溯寻找注释
                        check_idx = idx - 1
                        while check_idx >= 0:
                            prev_line = lines[check_idx].strip()
                            if prev_line == "":
                                check_idx -= 1
                                continue
                            elif prev_line.startswith("///"):
                                has_doc_comment = True
                                break
                            elif prev_line.startswith("//") or prev_line.endswith("*/"):
                                # 遇到普通注释或者多行注释结束，继续往上看
                                check_idx -= 1
                                continue
                            else:
                                # 遇到了其他代码行，说明没有文档注释
                                break
                                
                        if not has_doc_comment:
                            missing_funcs += 1
                            func_match = func_pattern.search(line)
                            func_name = func_match.group(1) if func_match else "unknown"
                            report.append({
                                'file': relative_path,
                                'line': idx + 1,
                                'func': func_name,
                                'signature': line.strip()
                            })
                            
    return report, total_funcs, missing_funcs

def main():
    workspace = "/Users/constantine/Documents/work/code/projects/ZhiYu"
    report, total, missing = scan_missing_comments(workspace)
    
    report_file = os.path.join(workspace, "build/missing_docs_report.txt")
    os.makedirs(os.path.dirname(report_file), exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(f"ZhiYu Project Missing Documentation Comments Report\n")
        f.write(f"Total Non-private Functions: {total}\n")
        f.write(f"Missing /// Comments: {missing} ({(missing/total*100):.2f}%)\n")
        f.write("="*80 + "\n\n")
        
        for item in report:
            f.write(f"File: {item['file']}:{item['line']}\n")
            f.write(f"Func: {item['func']}\n")
            f.write(f"Sign: {item['signature']}\n")
            f.write("-" * 40 + "\n")
            
    print(f"✅ 扫描完毕。总非私有函数数: {total}，缺失文档注释: {missing}。")
    print(f"📋 详细清单报告已输出至: build/missing_docs_report.txt")

if __name__ == "__main__":
    main()
