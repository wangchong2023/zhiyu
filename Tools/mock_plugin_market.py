#!/usr/bin/env python3
"""
Mock Plugin Market Server - 插件市场 Mock 服务器

提供端点：
- GET /api/plugins - 获取插件列表
- GET /api/plugins/{plugin_id} - 获取插件详情
- GET /plugins/{filename}.zyplugin - 下载插件
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime
import os

# 插件市场数据（包含远程插件的下载URL）
PLUGINS = [
    # ===== 远程插件（从市场下载） =====
    {
        "id": "com.zhiyu.plugin.remote.link-preview",
        "name": "[远程] 链接预览",
        "author": "ZhiYu Remote Team",
        "version": "1.0.0",
        "description": "自动获取 URL 的 meta 信息，生成包含图片和描述的丰富预览卡片",
        "icon": "link",
        "category": "内容增强",
        "tags": ["remote", "link", "preview", "network"],
        "downloads": 8500,
        "rating": 4.7,
        "permissions": ["readContent", "writeContent", "network"],
        "capabilities": ["postProcess"],
        "downloadURL": "http://localhost:9091/plugins/link-preview-remote.zyplugin",
        "lastUpdated": "2026-06-06T01:29:00Z"
    },
    {
        "id": "com.zhiyu.plugin.remote.ai-translator",
        "name": "[远程] AI 翻译器",
        "author": "ZhiYu Remote Team",
        "version": "1.0.0",
        "description": "使用 AI 服务自动翻译选中的文本，支持多种语言互译",
        "icon": "globe",
        "category": "AI 增强",
        "tags": ["remote", "ai", "translation", "multilingual"],
        "downloads": 12300,
        "rating": 4.9,
        "permissions": ["readContent", "writeContent", "aiAccess"],
        "capabilities": ["postProcess"],
        "downloadURL": "http://localhost:9091/plugins/ai-translator-remote.zyplugin",
        "lastUpdated": "2026-06-06T01:30:00Z"
    },
    # ===== 社区插件 =====
    {
        "id": "markdown-beautifier",
        "name": "Markdown 美化器",
        "author": "ZhiYu Team",
        "version": "1.0.0",
        "description": "自动格式化和美化 Markdown 文档",
        "icon": "doc.text.fill",
        "category": "编辑增强",
        "tags": ["markdown", "formatter", "productivity"],
        "downloads": 12500,
        "rating": 4.8,
        "permissions": ["content"],
        "capabilities": ["preProcess", "postProcess"],
        "downloadURL": "http://localhost:9091/plugins/smart-cleaner.zyplugin",
        "lastUpdated": "2026-05-15T10:30:00Z"
    },
    {
        "id": "ai-summary",
        "name": "AI 摘要生成",
        "author": "Community",
        "version": "2.1.0",
        "description": "智能提取文档核心要点，生成结构化摘要",
        "icon": "sparkles",
        "category": "AI 增强",
        "tags": ["ai", "summary", "nlp"],
        "downloads": 8300,
        "rating": 4.6,
        "permissions": ["content", "network"],
        "capabilities": ["postProcess"],
        "downloadURL": None,
        "lastUpdated": "2026-06-01T14:20:00Z"
    },
    {
        "id": "code-highlighter",
        "name": "代码高亮",
        "author": "DevTools",
        "version": "1.5.2",
        "description": "为代码块添加语法高亮和行号",
        "icon": "curlybraces",
        "category": "编辑增强",
        "tags": ["code", "syntax", "highlight"],
        "downloads": 15600,
        "rating": 4.9,
        "permissions": ["content"],
        "capabilities": ["preProcess"],
        "downloadURL": None,
        "lastUpdated": "2026-05-28T09:15:00Z"
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
                "timestamp": int(datetime.now().timestamp())
            }
            self.wfile.write(json.dumps(response, ensure_ascii=False).encode())
        
        elif self.path.startswith("/api/plugins/"):
            plugin_id = self.path.split("/")[-1]
            plugin = next((p for p in PLUGINS if p["id"] == plugin_id), None)
            
            if plugin:
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "code": 0,
                    "message": "success",
                    "data": plugin,
                    "timestamp": int(datetime.now().timestamp())
                }
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode())
            else:
                self.send_response(404)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "code": 404,
                    "message": f"Plugin {plugin_id} not found",
                    "data": None,
                    "timestamp": int(datetime.now().timestamp())
                }
                self.wfile.write(json.dumps(response).encode())
        
        elif self.path.startswith("/plugins/"):
            # 提供插件下载
            filename = self.path.split("/")[-1]
            
            # 查找插件文件
            remote_path = f"Tools/Plugins/Remote/{filename}"
            local_path = f"Tools/Plugins/{filename}"
            
            file_path = None
            if os.path.exists(remote_path):
                file_path = remote_path
            elif os.path.exists(local_path):
                file_path = local_path
            
            if file_path:
                self.send_response(200)
                self.send_header("Content-Type", "application/zip")
                self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
                self.end_headers()
                
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

if __name__ == "__main__":
    port = 9091
    server = HTTPServer(("localhost", port), MockPluginHandler)
    print(f"Mock Plugin Market 已启动在 http://localhost:{port}")
    print(f"API 端点:")
    print(f"  - GET http://localhost:{port}/api/plugins")
    print(f"  - GET http://localhost:{port}/api/plugins/{{plugin_id}}")
    print(f"  - GET http://localhost:{port}/plugins/{{filename}}.zyplugin")
    print("\n按 Ctrl+C 停止服务器")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n服务器已停止")
