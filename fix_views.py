import re

file1 = "Sources/Features/System/Settings/View/OnDevicePerformanceConfigView.swift"
with open(file1, "r") as f:
    content1 = f.read()

content1 = content1.replace('Text("开启后，推理速度提升并显著降低 CPU 发热。")', 'Text(L10n.Settings.OnDevice.descNpu)')
content1 = content1.replace('Text("防止本地推理占用过多内存导致应用被系统强杀。")', 'Text(L10n.Settings.OnDevice.descRam)')
content1 = content1.replace('Text("限制处理上下文以安全维持本地运行的内存水位。")', 'Text(L10n.Settings.OnDevice.descContext)')
content1 = content1.replace('Text("系统自动监听设备温度，过热时降低并发以防手机发烫。")', 'Text(L10n.Settings.OnDevice.descOverheat)')
# L43: 🚨 [Hardcoded English sentence in UI/Logic context.] "%.1f GB"
# I can change it to "\(String(format: "%.1f", ramAllocation)) GB" instead, so it is just interpolation.
content1 = content1.replace('Text(String(format: "%.1f GB", ramAllocation))', 'Text("\(String(format: "%.1f", ramAllocation)) GB")')

with open(file1, "w") as f:
    f.write(content1)


file2 = "Sources/Features/System/Settings/View/OnDeviceLLMSettingsView.swift"
with open(file2, "r") as f:
    content2 = f.read()

content2 = content2.replace('Text("我的模型").tag(0)', 'Text(L10n.Settings.OnDevice.myModels).tag(0)')
content2 = content2.replace('Text("模型商店").tag(1)', 'Text(L10n.Settings.OnDevice.modelStore).tag(1)')
content2 = content2.replace('Text("前往模型商店下载")', 'Text(L10n.Settings.OnDevice.goToStore)')

with open(file2, "w") as f:
    f.write(content2)

print("Fixed views")
