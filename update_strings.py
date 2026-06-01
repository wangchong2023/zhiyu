import json
import sys

file_path = "Sources/Localization/Catalogs/System.xcstrings"

with open(file_path, "r") as f:
    data = json.load(f)

new_strings = {
    "settings.aiArchitectureExplanation": {
        "en": "💡 ZhiYu uses an edge-cloud architecture. \"Online Models\" leverage cloud computing for powerful RAG synthesis. \"On-Device Model Hub\" uses local processing for offline, privacy-first scanning.",
        "zh-Hans": "💡 智宇采用端云协同架构。“在线大模型”通过云端网络为您提供更强大的混合 RAG 深度检索与合成；“端侧模型中枢”使用您设备的本地算力，在 100% 离线和隐私保护下完成后台笔记扫描与标签提取。"
    },
    "settings.onlineLLM": {
        "en": "Online Model Hub",
        "zh-Hans": "在线模型中枢"
    },
    "settings.onDeviceLLMHub": {
        "en": "On-Device Model Hub",
        "zh-Hans": "端侧模型中枢"
    },
    "ondevice.whatIsOnDevice": {
        "en": "📱 What is an On-Device Model?",
        "zh-Hans": "📱 什么是端侧大模型？"
    },
    "ondevice.whatIsOnDeviceDesc": {
        "en": "After downloading, ZhiYu can run entirely offline. Your notes are analyzed with 100% privacy and zero cost. We recommend downloading Gemma-2B.",
        "zh-Hans": "下载本地模型后，智宇将能够完全脱离网络运行。您的笔记分析、自动标签提取等任务都将在您的本地设备上以 100% 离线、零资费的方式进行，保障绝对的隐私安全。推荐下载 Gemma-2B 开始体验。"
    },
    "ondevice.npuAcceleration": {
        "en": "NPU Hardware Acceleration",
        "zh-Hans": "NPU 硬件加速"
    },
    "ondevice.ramAllocation": {
        "en": "RAM Allocation Limit",
        "zh-Hans": "物理运存配额"
    },
    "ondevice.maxContext": {
        "en": "Max Context Length",
        "zh-Hans": "最大上下文长度"
    },
    "ondevice.overheatProtection": {
        "en": "Adaptive Thermal Overheat Protection",
        "zh-Hans": "自适应过热保护"
    }
}

for key, trans in new_strings.items():
    data["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": trans["en"]
                }
            },
            "zh-Hans": {
                "stringUnit": {
                    "state": "translated",
                    "value": trans["zh-Hans"]
                }
            }
        }
    }

with open(file_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Updated System.xcstrings")
