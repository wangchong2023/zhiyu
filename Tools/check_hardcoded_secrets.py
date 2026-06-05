#!/usr/bin/env python3
"""
硬编码敏感信息检查工具

检查内容：
- HTTP/HTTPS URL
- IP 地址和端口
- API 密钥
- 账户凭证
- 数据库连接字符串
"""

import re
import os
from pathlib import Path

def check_hardcoded_info(root_dir='Sources'):
    """扫描硬编码信息"""
    
    issues = {
        'urls': [],
        'ips': [],
        'api_keys': [],
        'credentials': [],
        'other': []
    }
    
    # 排除的目录和文件
    exclude_dirs = {'.git', 'build', 'DerivedData', '.build', 'Frameworks', 'Tests'}
    exclude_files = {'AppConfig.json', 'AppConfig.swift'}  # 配置文件允许
    
    # 正则模式
    patterns = {
        'http_url': re.compile(r'https?://[^\s\'"<>]+'),
        'ip_address': re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b'),
        'api_key': re.compile(r'(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*["\']([^"\']{8,})["\']'),
        'bearer': re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
        'basic_auth': re.compile(r'Basic\s+[A-Za-z0-9+/]+=*'),
        'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    }
    
    for root, dirs, files in os.walk(root_dir):
        # 过滤排除目录
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        
        for file in files:
            if not file.endswith('.swift'):
                continue
            
            if file in exclude_files:
                continue
            
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path)
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for line_num, line in enumerate(lines, 1):
                        # 跳过注释
                        if line.strip().startswith('//'):
                            continue
                        
                        # 检查 HTTP URL
                        urls = patterns['http_url'].findall(line)
                        for url in urls:
                            # 过滤测试 URL 和占位符
                            if any(x in url.lower() for x in ['example.com', 'localhost', 'test.com', 'placeholder']):
                                continue
                            issues['urls'].append((rel_path, line_num, line.strip(), url))
                        
                        # 检查 IP 地址
                        ips = patterns['ip_address'].findall(line)
                        for ip in ips:
                            # 过滤 localhost 和私有 IP
                            if ip.startswith(('127.', '0.0.0.0', 'localhost')):
                                continue
                            issues['ips'].append((rel_path, line_num, line.strip(), ip))
                        
                        # 检查 API 密钥
                        api_keys = patterns['api_key'].findall(line)
                        for key_name, key_value in api_keys:
                            issues['api_keys'].append((rel_path, line_num, line.strip(), f"{key_name} = {key_value}"))
                        
                        # 检查 Bearer Token
                        if patterns['bearer'].search(line):
                            issues['credentials'].append((rel_path, line_num, line.strip(), 'Bearer Token'))
                        
                        # 检查 Basic Auth
                        if patterns['basic_auth'].search(line):
                            issues['credentials'].append((rel_path, line_num, line.strip(), 'Basic Auth'))
                        
                        # 检查邮箱地址
                        emails = patterns['email'].findall(line)
                        for email in emails:
                            if 'example' not in email.lower():
                                issues['other'].append((rel_path, line_num, line.strip(), f'Email: {email}'))
            
            except Exception as e:
                pass
    
    return issues

def print_report(issues):
    """打印报告"""
    print("=" * 80)
    print("硬编码敏感信息检查报告")
    print("=" * 80)
    print()
    
    total = sum(len(v) for v in issues.values())
    
    if total == 0:
        print("✅ 未发现硬编码敏感信息")
        return
    
    print(f"⚠️  发现 {total} 处潜在问题\n")
    
    # HTTP URL
    if issues['urls']:
        print(f"🌐 HTTP/HTTPS URL ({len(issues['urls'])} 处)")
        print("-" * 80)
        for path, line_num, line, url in issues['urls'][:10]:  # 只显示前10个
            print(f"  📄 {path}:{line_num}")
            print(f"     URL: {url}")
            print(f"     代码: {line[:80]}")
            print()
        if len(issues['urls']) > 10:
            print(f"     ... 还有 {len(issues['urls']) - 10} 处\n")
    
    # IP 地址
    if issues['ips']:
        print(f"🔢 IP 地址 ({len(issues['ips'])} 处)")
        print("-" * 80)
        for path, line_num, line, ip in issues['ips']:
            print(f"  📄 {path}:{line_num}")
            print(f"     IP: {ip}")
            print(f"     代码: {line[:80]}")
            print()
    
    # API 密钥
    if issues['api_keys']:
        print(f"🔑 API 密钥/密码 ({len(issues['api_keys'])} 处)")
        print("-" * 80)
        for path, line_num, line, key_info in issues['api_keys']:
            print(f"  📄 {path}:{line_num}")
            print(f"     ⚠️  {key_info}")
            print(f"     代码: {line[:80]}")
            print()
    
    # 凭证
    if issues['credentials']:
        print(f"🔐 认证凭证 ({len(issues['credentials'])} 处)")
        print("-" * 80)
        for path, line_num, line, cred_type in issues['credentials']:
            print(f"  📄 {path}:{line_num}")
            print(f"     类型: {cred_type}")
            print(f"     代码: {line[:80]}")
            print()
    
    # 其他
    if issues['other']:
        print(f"📧 其他敏感信息 ({len(issues['other'])} 处)")
        print("-" * 80)
        for path, line_num, line, info in issues['other']:
            print(f"  📄 {path}:{line_num}")
            print(f"     信息: {info}")
            print(f"     代码: {line[:80]}")
            print()
    
    print("=" * 80)
    print("建议:")
    print("  1. 将所有 URL 移至配置文件 (AppConfig.json)")
    print("  2. 将敏感凭证移至环境变量或 Keychain")
    print("  3. 使用 .gitignore 排除包含敏感信息的文件")
    print("  4. 定期进行安全审计")
    print("=" * 80)

if __name__ == "__main__":
    issues = check_hardcoded_info()
    print_report(issues)
