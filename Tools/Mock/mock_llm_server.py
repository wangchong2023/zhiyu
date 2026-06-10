#!/usr/bin/env python3
"""
Mock LLM Server - 参考 Google AI Gallery 提供模型列表 API

提供端点：
- GET /api/models - 获取可用模型列表
- GET /api/models/{model_id} - 获取模型详情
- POST /api/chat/completions - OpenAI 兼容的聊天接口（Mock）
"""

from http.server import BaseHTTPRequestHandler
from datetime import datetime
from copy import deepcopy

from mock_constants import (
    HOST_ALL, PORT_LLM, HTTP_OK, HTTP_NOT_FOUND,
    DEFAULT_PARAMS, make_api_response, send_json, start_server
)

def _make_model(model_id, display_name, vendor, size, memory, filename, checksum, params_count, tasks, description):
    return {
        "modelId": model_id,
        "displayName": display_name,
        "vendor": vendor,
        "fileSizeInBytes": size,
        "minDeviceMemoryInGb": memory,
        "remoteURLString": f"http://localhost:{PORT_LLM}/models/{filename}",
        "sha256Checksum": checksum,
        "parameterCount": params_count,
        "supportedTasks": tasks,
        "description": description,
        "defaultParameters": deepcopy(DEFAULT_PARAMS)
    }

MODELS = [
    _make_model("llama3.2:3b", "Llama 3.2 3B", "Meta",
                2147483648, 4.0, "llama3.2-3b.gguf",
                "abc123", "3B", ["chat", "completion"],
                "轻量级对话模型，适合日常任务"),
    _make_model("qwen2.5:7b", "Qwen 2.5 7B", "Alibaba",
                5046586573, 8.0, "qwen2.5-7b.gguf",
                "def456", "7B", ["chat", "completion", "reasoning"],
                "中文友好的通用对话模型"),
    _make_model("deepseek-r1:8b", "DeepSeek R1 8B", "DeepSeek",
                5579096883, 8.0, "deepseek-r1-8b.gguf",
                "ghi789", "8B", ["chat", "reasoning", "code"],
                "强化学习优化的推理模型"),
    _make_model("gemma2:9b", "Gemma 2 9B", "Google",
                6225789952, 10.0, "gemma2-9b.gguf",
                "jkl012", "9B", ["chat", "completion"],
                "Google 开源的高性能模型"),
]

class MockLLMHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/models":
            send_json(self, HTTP_OK,
                      make_api_response(MODELS))
        elif self.path.startswith("/api/models/"):
            model_id = self.path.split("/")[-1]
            model = next((m for m in MODELS if m["modelId"] == model_id), None)
            if model:
                send_json(self, HTTP_OK,
                          make_api_response(model))
            else:
                send_json(self, HTTP_NOT_FOUND,
                          make_api_response(None, code=HTTP_NOT_FOUND,
                                            message=f"Model {model_id} not found"))
        else:
            send_json(self, HTTP_NOT_FOUND,
                      make_api_response(None, code=HTTP_NOT_FOUND))

    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

if __name__ == "__main__":
    start_server(MockLLMHandler, PORT_LLM, host=HOST_ALL, name="mock_llm_server")
