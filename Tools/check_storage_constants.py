#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gatekeeper Script: Check Storage Constants
用于监控代码中是否直接使用了硬编码的物理表名、字段名或手写 SQL，而没有使用 AppConstants.Storage。
"""

import os
import re
import sys

def check_file(filepath):
    issues = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return issues
        
    # Physical field rules
    column_pattern = re.compile(r't\.column\(\s*"\w+"')
    auto_pk_pattern = re.compile(r't\.autoIncrementedPrimaryKey\(\s*"\w+"\)')
    pk_array_pattern = re.compile(r't\.primaryKey\(\s*\[\s*"\w+"')
    
    # Hardcoded SQL rules
    # Match keywords followed by a bare table name (no string interpolation \()
    sql_table_pattern = re.compile(r'(?i)\b(FROM|INTO|UPDATE|JOIN|TABLE)\s+(\w+)\b')
    ignore_words = {'select', 'insert', 'update', 'delete', 'where', 'set', 'or', 'ignore', 'replace', 'into', 'from', 'table', 'if', 'not', 'exists', 'sqlite_master'}
    
    for i, line in enumerate(lines):
        line = line.strip()
        
        # Skip comments
        if line.startswith('//'):
            continue
            
        # Check physical fields
        if column_pattern.search(line):
            issues.append((i + 1, f"硬编码的物理字段 (t.column): {line}"))
        if auto_pk_pattern.search(line):
            issues.append((i + 1, f"硬编码的物理字段 (t.autoIncrementedPrimaryKey): {line}"))
        if pk_array_pattern.search(line):
            issues.append((i + 1, f"硬编码的物理字段 (t.primaryKey): {line}"))
            
        # Check SQL
        if 'sql:' in line or 'db.execute(' in line or 'Row.fetchAll(' in line:
            # We look for literal table names without \(
            # Check if there is an interpolated string for table
            if r'\(' not in line:
                match = sql_table_pattern.search(line)
                if match:
                    table_name = match.group(2).lower()
                    if table_name not in ignore_words and not table_name.startswith('sqlite_'):
                        issues.append((i + 1, f"硬编码的 SQL 表名 '{match.group(2)}': {line}"))
                        
    return issues

def main():
    sources_dir = "Sources"
    found_issues = False
    
    # Allow-list files that might legitimately contain schema definitions or where the constants are defined
    allow_list = [
        "AppConstants.swift",
    ]
    
    for root, dirs, files in os.walk(sources_dir):
        for file in files:
            if file.endswith('.swift'):
                if file in allow_list:
                    continue
                filepath = os.path.join(root, file)
                issues = check_file(filepath)
                if issues:
                    print(f"❌ 发现硬编码的物理字段或 SQL 在文件: {filepath}")
                    for line, msg in issues:
                        print(f"   -> 行 {line}: {msg}")
                    found_issues = True
                    
    if found_issues:
        print("\n❌ 编译阻断: 检测到直接使用了物理表字段或硬编码SQL。请使用 AppConstants.Storage 中定义的常量！")
        sys.exit(1)
    else:
        print("✅ 存储常量检查通过。未发现硬编码的物理表字段或 SQL。")
        sys.exit(0)

if __name__ == "__main__":
    main()
