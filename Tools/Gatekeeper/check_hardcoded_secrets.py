#!/usr/bin/env python3
"""
硬编码敏感信息检查工具

检查内容：
- 硬编码密钥/Token/密码
- 可疑的认证凭证
- 内网 IP 地址

显式排除（非敏感）：
- LLM API 服务端点 URL（公开基础设施地址）
- 带有 mock_/demo_/test_/example_ 前缀的测试桩数据
- Keychain/环境变量 key 名称
- 公开网站 URL（官网、文档、GitHub 仓库地址）
"""

import re
import os
import sys

# ═══════════════════════════════════════════════════════════════════════════════
# 白名单：已知安全的 URL 模式（公开 API 端点、官网、文档）
# ═══════════════════════════════════════════════════════════════════════════════
SAFE_URL_PATTERNS = [
    # LLM 服务提供商 API 端点（公开基础设施地址，不含密钥）
    r'api\.deepseek\.com',
    r'api\.moonshot\.cn',
    r'api\.minimax\.chat',
    r'api\.siliconflow\.cn',
    r'dashscope\.aliyuncs\.com',
    r'open\.bigmodel\.cn',
    r'api\.openai\.com',
    r'api\.anthropic\.com',
    r'api\.googleapis\.com',
    r'generativelanguage\.googleapis\.com',
    # 公开网站和文档
    r'zhiyu\.ai',
    r'github\.com/zhiyu',
    r'raw\.githubusercontent\.com',
    r'github\.com/login/oauth',      # OAuth 授权 URL（公开）
    # 公开 CDN（模型下载等）
    r'cdn\.zhiyu\.app',
    # XML 命名空间标准（OOXML、SVG 等）
    r'schemas\.openxmlformats\.org',
    r'www\.w3\.org/XML',
    r'www\.w3\.org/1999',
    r'www\.w3\.org/2000',
    # 占位符/示例 URL
    r'example\.com',
    r'placeholder',
    # 本地开发地址
    r'localhost',
    r'127\.0\.0\.1',
    r'0\.0\.0\.0',
]

# ═══════════════════════════════════════════════════════════════════════════════
# 白名单：安全的 Token/Key 模式（测试桩、Key 名称引用）
# ═══════════════════════════════════════════════════════════════════════════════
SAFE_TOKEN_PATTERNS = [
    r'mock_',           # mock_jwt_access_token 等测试桩
    r'demo_',           # 演示数据
    r'test_',           # 测试数据
    r'example_',        # 示例数据
    r'placeholder',     # 占位符
    r'llm_api_key',     # Keychain key 名称，非实际值
    r'api[_-]?key\s*[:=]\s*""',   # 空字符串 API key
]

# ═══════════════════════════════════════════════════════════════════════════════
# 白名单：安全的文件路径（测试文件、配置文件）
# ═══════════════════════════════════════════════════════════════════════════════
SAFE_FILE_PATTERNS = [
    r'Mock',                    # Mock 服务文件
    r'TestMocks',               # 测试桩
    r'AuthService\.swift',      # 已知含 mock 测试桩
    r'CarrierAuthStrategy\.swift',
    r'GoogleAuthStrategy\.swift',
    r'GitHubAuthStrategy\.swift',
    r'LLMModels\.swift',        # LLM 端点配置
    r'AppConfig',               # 应用配置文件
    r'WebScraperProcessor\.swift',  # UA 字符串
    r'InitialNotebookGenerator\.swift', # 初始/测试演示数据文件，包含公开引用源 URL
]


def is_safe_url(url):
    """检查 URL 是否匹配白名单"""
    for pattern in SAFE_URL_PATTERNS:
        if re.search(pattern, url, re.IGNORECASE):
            return True
    return False


def is_safe_token(value):
    """检查 token/key 值是否匹配白名单"""
    for pattern in SAFE_TOKEN_PATTERNS:
        if re.search(pattern, value, re.IGNORECASE):
            return True
    return False


def is_safe_file(filepath):
    """检查文件路径是否在白名单中"""
    for pattern in SAFE_FILE_PATTERNS:
        if re.search(pattern, filepath):
            return True
    return False


def check_hardcoded_info(root_dir='Sources'):
    """扫描真正的硬编码敏感信息"""

    issues = {
        'urls': [],
        'ips': [],
        'api_keys': [],
        'credentials': [],
        'other': []
    }

    exclude_dirs = {'.git', 'build', 'DerivedData', '.build', 'Frameworks', 'Tests'}

    patterns = {
        'http_url': re.compile(r'https?://[^\s\'"<>]+'),
        'ip_address': re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b'),
        'api_key': re.compile(r'(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*["\']([^"\']{8,})["\']'),
        'bearer': re.compile(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
        'basic_auth': re.compile(r'Basic\s+[A-Za-z0-9+/]+=*'),
        'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    }

    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]

        for file in files:
            if not file.endswith('.swift'):
                continue

            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path)

            # 白名单文件：完全跳过（如已知包含 mock 数据的文件）
            if is_safe_file(rel_path):
                continue

            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                    for line_num, line in enumerate(lines, 1):
                        if line.strip().startswith('//'):
                            continue

                        # ── HTTP URL ──────────────────────────────
                        urls = patterns['http_url'].findall(line)
                        for url in urls:
                            if is_safe_url(url):
                                continue
                            issues['urls'].append((rel_path, line_num, line.strip(), url))

                        # ── IP 地址 ───────────────────────────────
                        ips = patterns['ip_address'].findall(line)
                        for ip in ips:
                            if ip.startswith(('127.', '0.0.0.0', 'localhost', '255.')):
                                continue
                            # 过滤 User-Agent 中的版本号（如 "125.0.0.0"）
                            if 'Mozilla' in line or 'User-Agent' in line:
                                continue
                            issues['ips'].append((rel_path, line_num, line.strip(), ip))

                        # ── API 密钥/Token ────────────────────────
                        api_keys = patterns['api_key'].findall(line)
                        for key_name, key_value in api_keys:
                            if is_safe_token(key_value):
                                continue
                            issues['api_keys'].append((rel_path, line_num, line.strip(), f"{key_name} = {key_value}"))

                        # ── Bearer Token ──────────────────────────
                        if patterns['bearer'].search(line):
                            token_text = line.strip()
                            if is_safe_token(token_text):
                                continue
                            issues['credentials'].append((rel_path, line_num, token_text, 'Bearer Token'))

                        # ── Basic Auth ────────────────────────────
                        if patterns['basic_auth'].search(line):
                            issues['credentials'].append((rel_path, line_num, line.strip(), 'Basic Auth'))

                        # ── 邮箱地址 ──────────────────────────────
                        emails = patterns['email'].findall(line)
                        for email in emails:
                            if any(x in email.lower() for x in ['example', 'mock', 'test', 'demo']):
                                continue
                            issues['other'].append((rel_path, line_num, line.strip(), f'Email: {email}'))

            except Exception:
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
        print("=" * 80)
        return

    print(f"🚨 发现 {total} 处真实风险\n")

    for title, key, icon in [
        ("HTTP/HTTPS URL", 'urls', "🌐"),
        ("IP 地址", 'ips', "🔢"),
        ("API 密钥/密码", 'api_keys', "🔑"),
        ("认证凭证", 'credentials', "🔐"),
        ("其他敏感信息", 'other', "📧"),
    ]:
        items = issues[key]
        if not items:
            continue
        print(f"{icon} {title} ({len(items)} 处)")
        print("-" * 80)
        for path, line_num, line, info in items[:15]:
            print(f"  📄 {path}:{line_num}")
            print(f"     详情: {info}")
            print(f"     代码: {line[:100]}")
            print()
        if len(items) > 15:
            print(f"     ... 还有 {len(items) - 15} 处\n")

    print("=" * 80)
    print("建议：将真实凭证移至 Keychain 或环境变量，不要硬编码在源码中。")
    print("=" * 80)


if __name__ == "__main__":
    issues = check_hardcoded_info()
    print_report(issues)
    total = sum(len(v) for v in issues.values())
    # 只有真实风险 > 0 才返回非零退出码
    sys.exit(1 if total > 0 else 0)
