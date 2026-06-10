import json
import os
import time
from http.server import HTTPServer
from uuid import uuid4

HOST_ALL = "0.0.0.0"
HOST_LOCAL = "127.0.0.1"

PORT_LLM = 8080
PORT_PLUGIN = 9091
PORT_MODEL = 30080

HTTP_OK = 200
HTTP_NOT_FOUND = 404

CODE_SUCCESS = 0

DEFAULT_PARAMS = {
    "temperature": 0.7,
    "topP": 0.9,
    "topK": 40,
    "maxTokens": 2048
}

PLUGIN_BASE_URL = "http://localhost:9091/plugins/"
PLUGIN_SEARCH_DIRS = ["Tools/Plugins/Remote", "Tools/Plugins", "Tools/Plugins/community"]

PID_DIR = "/tmp"

MSG_SUCCESS = "success"


def make_api_response(data, code=CODE_SUCCESS, message=MSG_SUCCESS):
    return {
        "code": code,
        "message": message,
        "data": data,
        "requestId": f"req_{int(time.time())}",
        "timestamp": int(time.time())
    }


def make_api_response_ms(data, code=CODE_SUCCESS, message=MSG_SUCCESS):
    return {
        "code": code,
        "message": message,
        "data": data,
        "requestId": str(uuid4()),
        "timestamp": int(time.time() * 1000)
    }


def send_json(handler, status, body):
    payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(payload)))
    handler.end_headers()
    handler.wfile.write(payload)


def save_pid(name):
    pid_path = os.path.join(PID_DIR, f"{name}.pid")
    with open(pid_path, "w") as f:
        f.write(str(os.getpid()))


def start_server(handler_class, port, host=HOST_ALL, name="mock"):
    server = HTTPServer((host, port), handler_class)
    save_pid(name)
    print(f"[{name}] Mock 服务已启动 → http://{host}:{port}")
    print(f"[{name}] 按 Ctrl+C 停止")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\n[{name}] 已停止")
        server.server_close()
