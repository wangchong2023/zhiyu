import json

file_path = "Sources/Localization/Catalogs/System.xcstrings"

with open(file_path, "r") as f:
    data = json.load(f)

new_strings = {
    "ondevice.desc.npu": {
        "en": "When enabled, inference speed increases while significantly reducing CPU heat.",
        "zh-Hans": "开启后，推理速度提升并显著降低 CPU 发热。"
    },
    "ondevice.desc.ram": {
        "en": "Prevents local inference from occupying too much memory, avoiding system termination.",
        "zh-Hans": "防止本地推理占用过多内存导致应用被系统强杀。"
    },
    "ondevice.desc.context": {
        "en": "Limits the context processed to safely maintain local memory watermarks.",
        "zh-Hans": "限制处理上下文以安全维持本地运行的内存水位。"
    },
    "ondevice.desc.overheat": {
        "en": "Automatically monitors device temperature and reduces concurrency when overheating.",
        "zh-Hans": "系统自动监听设备温度，过热时降低并发以防手机发烫。"
    },
    "ondevice.goToStore": {
        "en": "Go to Model Store to Download",
        "zh-Hans": "前往模型商店下载"
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

print("Updated System.xcstrings 2")
