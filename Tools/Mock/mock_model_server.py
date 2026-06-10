#!/usr/bin/env python3
"""
端侧大模型商店 Mock 服务端

提供 /api/ai/models/allowlist 接口，返回符合 ApiResponse<[LLMManifest]> 格式的模型清单。
默认监听 0.0.0.0:30080，与 AppConfig.json 中的 backend_base_url 对齐。
"""

import time
from http.server import BaseHTTPRequestHandler
from copy import deepcopy

from mock_constants import (
    HOST_LOCAL, PORT_MODEL, HTTP_OK, HTTP_NOT_FOUND,
    make_api_response_ms, send_json, start_server
)

DEFAULT_PARAMS_Q4 = {"temperature": 0.7, "topP": 0.9, "topK": 40, "maxTokens": 2048}
DEFAULT_PARAMS_LLAMA = {"temperature": 0.6, "topP": 0.95, "topK": 50, "maxTokens": 4096}
DEFAULT_PARAMS_PHI = {"temperature": 0.5, "topP": 0.85, "topK": 30, "maxTokens": 2048}

MODEL_PARAMS_BY_TASK = {
    "Chunking": DEFAULT_PARAMS_Q4,
    "Chat": DEFAULT_PARAMS_Q4,
    "Synthesis": DEFAULT_PARAMS_LLAMA,
}


def _make_model(model_id, display_name, vendor, size, memory, filename, checksum,
                params_count, tasks, description, params=None):
    return {
        "modelId": model_id,
        "displayName": display_name,
        "vendor": vendor,
        "fileSizeInBytes": size,
        "minDeviceMemoryInGb": memory,
        "remoteURLString": f"https://cdn.zhiyu.app/models/{filename}",
        "sha256Checksum": checksum,
        "parameterCount": params_count,
        "supportedTasks": tasks,
        "description": description,
        "defaultParameters": deepcopy(params or DEFAULT_PARAMS_Q4)
    }


ALLOWLIST = [
    _make_model("gemma-2b-it", "Gemma-2-2B-IT", "Google",
                1530000000, 6.0, "gemma-2b-it-q4.bin",
                "21dbdf737aa7134914101e4a42828a2a7134914101e4a428",
                "2B", ["Chunking", "LinkDiscovery", "Chat"],
                "Google 轻量级端侧大模型，2B 参数，专为语义分块与反链发现优化，极低功耗",
                params=DEFAULT_PARAMS_Q4),
    _make_model("llama3-8b-instruct", "Llama-3-8B-Instruct", "Meta",
                4610000000, 12.0, "llama-3-8b-q4.bin",
                "a7134aa7e42828a2a7134914101e4a42828a2a7134aa7e42828a2a7134914101e",
                "8B", ["Chat", "Synthesis"],
                "Meta 开源旗舰指令模型，8B 参数，适合复杂推理与知识合成",
                params=DEFAULT_PARAMS_LLAMA),
    _make_model("phi3-mini-instruct", "Phi-3-Mini-Instruct", "Microsoft",
                2360000000, 8.0, "phi-3-mini-q4.bin",
                "31dbdf737aa7134914101e4a42828a2a7134914101e4a428",
                "3.8B", ["Chat", "Tagging", "Chunking"],
                "Microsoft 高效小模型，3.8B 参数，在标签与语义理解任务上表现出色",
                params=DEFAULT_PARAMS_PHI),
]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/ai/models/allowlist":
            body = make_api_response_ms(ALLOWLIST)
            send_json(self, HTTP_OK, body)
        elif self.path == "/health":
            body = make_api_response_ms("ok")
            send_json(self, HTTP_OK, body)
        else:
            body = make_api_response_ms(None, code=HTTP_NOT_FOUND)
            send_json(self, HTTP_NOT_FOUND, body)

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    start_server(Handler, PORT_MODEL, host=HOST_LOCAL, name="mock_model_server")
