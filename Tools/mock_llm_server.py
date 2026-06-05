#!/usr/bin/env python3
"""
Mock LLM Server - 参考 Google AI Gallery 提供模型列表 API

提供端点：
- GET /api/models - 获取可用模型列表
- GET /api/models/{model_id} - 获取模型详情
- POST /api/chat/completions - OpenAI 兼容的聊天接口（Mock）
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime
import os

# 参考 Google AI Gallery 的模型数据结构
# 完全匹配 LLMManifest.swift 的字段
MODELS = [
    {
        "modelId": "llama3.2:3b",
        "displayName": "Llama 3.2 3B",
        "vendor": "Meta",
        "fileSizeInBytes": 2147483648,
        "minDeviceMemoryInGb": 4.0,
        "remoteURLString": "http://localhost:8080/models/llama3.2-3b.gguf",
        "sha256Checksum": "abc123",
        "parameterCount": "3B",
        "supportedTasks": ["chat", "completion"],
        "description": "轻量级对话模型，适合日常任务",
        "defaultParameters": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 40,
            "maxTokens": 2048
        }
    },
    {
        "modelId": "qwen2.5:7b",
        "displayName": "Qwen 2.5 7B",
        "vendor": "Alibaba",
        "fileSizeInBytes": 5046586573,
        "minDeviceMemoryInGb": 8.0,
        "remoteURLString": "http://localhost:8080/models/qwen2.5-7b.gguf",
        "sha256Checksum": "def456",
        "parameterCount": "7B",
        "supportedTasks": ["chat", "completion", "reasoning"],
        "description": "中文友好的通用对话模型",
        "defaultParameters": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 40,
            "maxTokens": 2048
        }
    },
    {
        "modelId": "deepseek-r1:8b",
        "displayName": "DeepSeek R1 8B",
        "vendor": "DeepSeek",
        "fileSizeInBytes": 5579096883,
        "minDeviceMemoryInGb": 8.0,
        "remoteURLString": "http://localhost:8080/models/deepseek-r1-8b.gguf",
        "sha256Checksum": "ghi789",
        "parameterCount": "8B",
        "supportedTasks": ["chat", "reasoning", "code"],
        "description": "强化学习优化的推理模型",
        "defaultParameters": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 40,
            "maxTokens": 2048
        }
    },
    {
        "modelId": "gemma2:9b",
        "displayName": "Gemma 2 9B",
        "vendor": "Google",
        "fileSizeInBytes": 6225789952,
        "minDeviceMemoryInGb": 10.0,
        "remoteURLString": "http://localhost:8080/models/gemma2-9b.gguf",
        "sha256Checksum": "jkl012",
        "parameterCount": "9B",
        "supportedTasks": ["chat", "completion"],
        "description": "Google 开源的高性能模型",
        "defaultParameters": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 40,
            "maxTokens": 2048
        }
    }
]

class MockLLMHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/models":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {
                "code": 0,
                "message": "success",
                "data": MODELS,
                "timestamp": int(datetime.now().timestamp())
            }
            self.wfile.write(json.dumps(response, ensure_ascii=False).encode())
        
        elif self.path.startswith("/api/models/"):
            model_id = self.path.split("/")[-1]
            model = next((m for m in MODELS if m["id"] == model_id), None)
            
            if model:
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "code": 0,
                    "message": "success",
                    "data": model,
                    "timestamp": int(datetime.now().timestamp())
                }
                self.wfile.write(json.dumps(response, ensure_ascii=False).encode())
            else:
                self.send_response(404)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "code": 404,
                    "message": f"Model {model_id} not found",
                    "data": None,
                    "timestamp": int(datetime.now().timestamp())
                }
                self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

if __name__ == "__main__":
    port = 8080
    # 🔧 修复：绑定到 0.0.0.0 以便 iOS 模拟器可以访问
    server = HTTPServer(("0.0.0.0", port), MockLLMHandler)

    # 保存 PID
    with open('/tmp/mock_llm_server.pid', 'w') as f:
        f.write(str(os.getpid()))

    print(f"Mock LLM Server 已启动在 http://0.0.0.0:{port}")
    print(f"API 端点:")
    print(f"  - GET http://localhost:{port}/api/models")
    print(f"  - GET http://127.0.0.1:{port}/api/models")
    print(f"  - GET http://localhost:{port}/api/models/{{model_id}}")
    print("\n按 Ctrl+C 停止服务器")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n服务器已停止")
