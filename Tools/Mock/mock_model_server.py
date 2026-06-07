#!/usr/bin/env python3
"""
端侧大模型商店 Mock 服务端

提供 /api/ai/models/allowlist 接口，返回符合 ApiResponse<[LLMManifest]> 格式的模型清单。
启动: python3 Tools/mock_model_server.py
默认监听 0.0.0.0:30080，与 AppConfig.json 中的 backend_base_url 对齐。
"""

import json
import time
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler

# ── 模型数据 ──────────────────────────────────────────────

ALLOWLIST = [
    {
        "modelId": "gemma-2b-it",
        "displayName": "Gemma-2-2B-IT",
        "vendor": "Google",
        "fileSizeInBytes": 1530000000,
        "minDeviceMemoryInGb": 6.0,
        "remoteURLString": "https://cdn.zhiyu.app/models/gemma-2b-it-q4.bin",
        "sha256Checksum": "21dbdf737aa7134914101e4a42828a2a7134914101e4a428",
        "parameterCount": "2B",
        "supportedTasks": ["Chunking", "LinkDiscovery", "Chat"],
        "description": "Google 轻量级端侧大模型，2B 参数，专为语义分块与反链发现优化，极低功耗",
        "defaultParameters": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 40,
            "maxTokens": 2048
        }
    },
    {
        "modelId": "llama3-8b-instruct",
        "displayName": "Llama-3-8B-Instruct",
        "vendor": "Meta",
        "fileSizeInBytes": 4610000000,
        "minDeviceMemoryInGb": 12.0,
        "remoteURLString": "https://cdn.zhiyu.app/models/llama-3-8b-q4.bin",
        "sha256Checksum": "a7134aa7e42828a2a7134914101e4a42828a2a7134aa7e42828a2a7134914101e",
        "parameterCount": "8B",
        "supportedTasks": ["Chat", "Synthesis"],
        "description": "Meta 开源旗舰指令模型，8B 参数，适合复杂推理与知识合成",
        "defaultParameters": {
            "temperature": 0.6,
            "topP": 0.95,
            "topK": 50,
            "maxTokens": 4096
        }
    },
    {
        "modelId": "phi3-mini-instruct",
        "displayName": "Phi-3-Mini-Instruct",
        "vendor": "Microsoft",
        "fileSizeInBytes": 2360000000,
        "minDeviceMemoryInGb": 8.0,
        "remoteURLString": "https://cdn.zhiyu.app/models/phi-3-mini-q4.bin",
        "sha256Checksum": "31dbdf737aa7134914101e4a42828a2a7134914101e4a428",
        "parameterCount": "3.8B",
        "supportedTasks": ["Chat", "Tagging", "Chunking"],
        "description": "Microsoft 高效小模型，3.8B 参数，在标签与语义理解任务上表现出色",
        "defaultParameters": {
            "temperature": 0.5,
            "topP": 0.85,
            "topK": 30,
            "maxTokens": 2048
        }
    }
]


def api_response(data):
    """构建符合 ApiResponse<T> 的统一响应格式"""
    return {
        "code": 0,
        "message": "success",
        "data": data,
        "requestId": str(uuid.uuid4()),
        "timestamp": int(time.time() * 1000)
    }


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, status, body):
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        pass  # 使用自定义日志替代默认格式

    def _log_request(self, status, body):
        now = time.strftime("%H:%M:%S")
        models = body.get("data", [])
        if isinstance(models, list):
            summary = f"{len(models)} models: {[m.get('displayName','?') for m in models]}"
        else:
            summary = str(models)
        print(f"[{now}] {self.command} {self.path} → {status} | {summary}", flush=True)

    def do_GET(self):
        if self.path == "/api/ai/models/allowlist":
            body = api_response(ALLOWLIST)
            self._send_json(200, body)
            self._log_request(200, body)
        elif self.path == "/health":
            body = api_response("ok")
            self._send_json(200, body)
            self._log_request(200, body)
        else:
            body = api_response(None)
            self._send_json(404, body)
            self._log_request(404, body)


if __name__ == "__main__":
    port = 30080
    HTTPServer.allow_reuse_address = True
    server = HTTPServer(("127.0.0.1", port), Handler)
    print(f"[mock-server] 模型商店 Mock 服务已启动 → http://127.0.0.1:{port}", flush=True)
    print(f"[mock-server] 端点: GET /api/ai/models/allowlist", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[mock-server] 已关闭")
        server.server_close()
