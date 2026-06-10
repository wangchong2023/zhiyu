#!/usr/bin/env python3
"""
Mock Plugin Market Server - 插件市场 Mock 服务器
"""

import json
import os
from http.server import BaseHTTPRequestHandler
from datetime import datetime

from mock_constants import (
    HOST_ALL, PORT_PLUGIN, HTTP_OK, HTTP_NOT_FOUND,
    PLUGIN_SEARCH_DIRS, MSG_SUCCESS,
    make_api_response, send_json, start_server
)

PLUGIN_VERSION_DEFAULT = "1.0.0"
PLUGIN_MIN_APP_VERSION = "1.0.0"
PLUGIN_MONETIZATION_FREE = {"model": "free"}
PLUGIN_HUB_BASE = "http://localhost:9091/plugins/"
PLUGIN_REQUIRED_PERMS = {
    "full": ["readContent", "writeContent", "network", "log"],
    "ai": ["readContent", "writeContent", "aiAccess", "log"],
    "minimal": ["readContent", "log"],
    "log": ["log"],
}


def _make_plugin(pid, author, downloads, rating, reviews, category, icon,
                 filename, names, descriptions, perms_key="full",
                 version=PLUGIN_VERSION_DEFAULT):
    return {
        "id": pid,
        "version": version,
        "author": author,
        "downloads": str(downloads),
        "rating": rating,
        "reviewCount": reviews,
        "category": category,
        "icon": icon,
        "downloadURL": f"{PLUGIN_HUB_BASE}{filename}",
        "minAppVersion": PLUGIN_MIN_APP_VERSION,
        "requiredPermissions": PLUGIN_REQUIRED_PERMS.get(perms_key, PLUGIN_REQUIRED_PERMS["log"]),
        "monetization": PLUGIN_MONETIZATION_FREE,
        "names": names,
        "descriptions": descriptions
    }


PLUGINS = [
    _make_plugin("com.zhiyu.plugin.remote.link-preview", "ZhiYu Remote Team",
                 8500, 4.7, 287, "内容增强", "link",
                 "link-preview-remote.zyplugin",
                 {"en": "Link Preview", "zh-Hans": "链接预览"},
                 {"en": "Auto fetches URL meta and generates rich preview cards.",
                  "zh-Hans": "自动获取 URL meta 信息，生成丰富预览卡片。"}),
    _make_plugin("com.zhiyu.plugin.remote.ai-translator", "ZhiYu Remote Team",
                 12300, 4.9, 425, "AI 增强", "globe",
                 "ai-translator-remote.zyplugin",
                 {"en": "AI Translator", "zh-Hans": "AI 翻译器"},
                 {"en": "Auto translate text using AI with multi-language support.",
                  "zh-Hans": "使用 AI 自动翻译文本，支持多语言。"},
                 perms_key="ai"),
    _make_plugin("com.zhiyu.plugin.markdown-beautifier", "ZhiYu Team",
                 12500, 4.8, 532, "编辑增强", "doc.text.fill",
                 "smart-cleaner.zyplugin",
                 {"en": "Markdown Beautifier", "zh-Hans": "Markdown 美化器"},
                 {"en": "Auto format and beautify Markdown documents.",
                  "zh-Hans": "自动格式化和美化 Markdown 文档。"}),
    _make_plugin("com.zhiyu.plugin.ai-summary", "Community",
                 8300, 4.6, 189, "AI 增强", "sparkles",
                 "ai-summary.zyplugin",
                 {"en": "AI Summary Generator", "zh-Hans": "AI 摘要生成"},
                 {"en": "Extract key points and generate structured summaries.",
                  "zh-Hans": "提取核心要点，生成结构化摘要。"},
                 perms_key="minimal",
                 version="2.1.0"),
    _make_plugin("com.zhiyu.plugin.code-highlighter", "DevTools",
                 15600, 4.9, 673, "编辑增强", "curlybraces",
                 "code-highlighter.zyplugin",
                 {"en": "Code Highlighter", "zh-Hans": "代码高亮"},
                 {"en": "Add syntax highlighting and line numbers to code blocks.",
                  "zh-Hans": "为代码块添加语法高亮和行号。"},
                 perms_key="minimal",
                 version="1.5.2"),
]


class MockPluginHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/plugins":
            send_json(self, HTTP_OK, make_api_response(PLUGINS))
        elif self.path.startswith("/api/plugins/"):
            pid = self.path.split("/")[-1]
            plugin = next((p for p in PLUGINS if p["id"] == pid), None)
            if plugin:
                send_json(self, HTTP_OK, {"code": 0, "data": plugin})
            else:
                send_json(self, HTTP_NOT_FOUND, make_api_response(None, code=HTTP_NOT_FOUND))
        elif self.path.startswith("/plugins/"):
            filename = self.path.split("/")[-1]
            for search_dir in PLUGIN_SEARCH_DIRS:
                fp = os.path.join(search_dir, filename)
                if os.path.exists(fp):
                    self.send_response(HTTP_OK)
                    self.send_header("Content-Type", "application/zip")
                    self.end_headers()
                    with open(fp, 'rb') as f:
                        self.wfile.write(f.read())
                    return
            send_json(self, HTTP_NOT_FOUND, make_api_response(None, code=HTTP_NOT_FOUND))
        else:
            send_json(self, HTTP_NOT_FOUND, make_api_response(None, code=HTTP_NOT_FOUND))

    def log_message(self, fmt, *args):
        print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {fmt % args}")

if __name__ == "__main__":
    start_server(MockPluginHandler, PORT_PLUGIN, host=HOST_ALL, name="mock_plugin_market")
