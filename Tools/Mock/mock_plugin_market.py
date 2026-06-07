#!/usr/bin/env python3
"""
Mock Plugin Market Server - 插件市场 Mock 服务器
"""

import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
from pathlib import Path

# 完全匹配 MarketPlugin Codable 结构的插件数据

PLUGINS = [
    {
        "id": "com.zhiyu.plugin.remote.link-preview",
        "version": "1.0.0",
        "author": "ZhiYu Remote Team",
        "downloads": "8500",
        "rating": 4.7,
        "reviewCount": 287,
        "category": "内容增强",
        "icon": "link",
        "downloadURL": "http://localhost:9091/plugins/link-preview-remote.zyplugin",
        "minAppVersion": "1.0.0",
        "requiredPermissions": [
            "readContent",
            "writeContent",
            "network",
            "log"
        ],
        "monetization": {
            "model": "free"
        },
        "names": {
            "en": "Link Preview",
            "zh-Hans": "链接预览"
        },
        "descriptions": {
            "en": "Auto fetches URL meta and generates rich preview cards.",
            "zh-Hans": "自动获取 URL meta 信息，生成丰富预览卡片。"
        }
    },
    {
        "id": "com.zhiyu.plugin.remote.ai-translator",
        "version": "1.0.0",
        "author": "ZhiYu Remote Team",
        "downloads": "12300",
        "rating": 4.9,
        "reviewCount": 425,
        "category": "AI 增强",
        "icon": "globe",
        "downloadURL": "http://localhost:9091/plugins/ai-translator-remote.zyplugin",
        "minAppVersion": "1.0.0",
        "requiredPermissions": [
            "readContent",
            "writeContent",
            "aiAccess",
            "log"
        ],
        "monetization": {
            "model": "free"
        },
        "names": {
            "en": "AI Translator",
            "zh-Hans": "AI 翻译器"
        },
        "descriptions": {
            "en": "Auto translate text using AI with multi-language support.",
            "zh-Hans": "使用 AI 自动翻译文本，支持多语言。"
        }
    },
    {
        "id": "com.zhiyu.plugin.markdown-beautifier",
        "version": "1.0.0",
        "author": "ZhiYu Team",
        "downloads": "12500",
        "rating": 4.8,
        "reviewCount": 532,
        "category": "编辑增强",
        "icon": "doc.text.fill",
        "downloadURL": "http://localhost:9091/plugins/smart-cleaner.zyplugin",
        "minAppVersion": "1.0.0",
        "requiredPermissions": [
            "readContent",
            "writeContent",
            "log"
        ],
        "monetization": {
            "model": "free"
        },
        "names": {
            "en": "Markdown Beautifier",
            "zh-Hans": "Markdown 美化器"
        },
        "descriptions": {
            "en": "Auto format and beautify Markdown documents.",
            "zh-Hans": "自动格式化和美化 Markdown 文档。"
        }
    },
    {
        "id": "com.zhiyu.plugin.ai-summary",
        "version": "2.1.0",
        "author": "Community",
        "downloads": "8300",
        "rating": 4.6,
        "reviewCount": 189,
        "category": "AI 增强",
        "icon": "sparkles",
        "downloadURL": "http://localhost:9091/plugins/ai-summary.zyplugin",
        "minAppVersion": "1.0.0",
        "requiredPermissions": [
            "readContent",
            "network",
            "log"
        ],
        "monetization": {
            "model": "free"
        },
        "names": {
            "en": "AI Summary Generator",
            "zh-Hans": "AI 摘要生成"
        },
        "descriptions": {
            "en": "Extract key points and generate structured summaries.",
            "zh-Hans": "提取核心要点，生成结构化摘要。"
        }
    },
    {
        "id": "com.zhiyu.plugin.code-highlighter",
        "version": "1.5.2",
        "author": "DevTools",
        "downloads": "15600",
        "rating": 4.9,
        "reviewCount": 673,
        "category": "编辑增强",
        "icon": "curlybraces",
        "downloadURL": "http://localhost:9091/plugins/code-highlighter.zyplugin",
        "minAppVersion": "1.0.0",
        "requiredPermissions": [
            "readContent",
            "log"
        ],
        "monetization": {
            "model": "free"
        },
        "names": {
            "en": "Code Highlighter",
            "zh-Hans": "代码高亮"
        },
        "descriptions": {
            "en": "Add syntax highlighting and line numbers to code blocks.",
            "zh-Hans": "为代码块添加语法高亮和行号。"
        }
    }
]


class MockPluginHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/plugins":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {
                "code": 0,
                "message": "success",
                "data": PLUGINS,
                "requestId": "req_" + str(int(datetime.now().timestamp())),
                "timestamp": int(datetime.now().timestamp())
            }
            self.wfile.write(json.dumps(response, ensure_ascii=False).encode())
        elif self.path.startswith("/api/plugins/"):
            pid = self.path.split("/")[-1]
            plugin = next((p for p in PLUGINS if p["id"] == pid), None)
            if plugin:
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"code": 0, "data": plugin}, ensure_ascii=False).encode())
            else:
                self.send_response(404); self.end_headers()
        elif self.path.startswith("/plugins/"):
            filename = self.path.split("/")[-1]
            for search_dir in ["Tools/Plugins/Remote", "Tools/Plugins", "Tools/Plugins/community"]:
                fp = os.path.join(search_dir, filename)
                if os.path.exists(fp):
                    self.send_response(200)
                    self.send_header("Content-Type", "application/zip")
                    self.end_headers()
                    with open(fp, 'rb') as f: self.wfile.write(f.read())
                    return
            self.send_response(404); self.end_headers()
        else:
            self.send_response(404); self.end_headers()

    def log_message(self, fmt, *args):
        print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {fmt % args}")

if __name__ == "__main__":
    port = 9091
    server = HTTPServer(("0.0.0.0", port), MockPluginHandler)
    with open('/tmp/mock_plugin_market.pid', 'w') as f:
        f.write(str(os.getpid()))
    print(f"Plugin Market @ 0.0.0.0:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped")
