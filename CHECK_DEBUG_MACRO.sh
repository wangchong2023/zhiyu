#!/bin/bash
echo "=== 检查 DEBUG 宏定义 ==="
echo ""

# 检查 project.pbxproj 中的 DEBUG 配置
echo "1. 检查 Xcode 项目配置："
grep -A 5 "Debug" ZhiYu.xcodeproj/project.pbxproj | grep "SWIFT_ACTIVE_COMPILATION_CONDITIONS" | head -3

echo ""
echo "2. 检查构建设置："
xcodebuild -project ZhiYu.xcodeproj -scheme ZhiYu -showBuildSettings 2>/dev/null | grep -E "CONFIGURATION|SWIFT_ACTIVE_COMPILATION_CONDITIONS" | head -5

echo ""
echo "3. 验证 AppConfig 读取："
echo "检查 AppConfig.json 是否正确..."
if [ -f "Sources/Resources/AppConfig.json" ]; then
    echo "✅ AppConfig.json 存在"
    cat Sources/Resources/AppConfig.json | python3 -m json.tool | grep -A 2 "model_store"
else
    echo "❌ AppConfig.json 不存在"
fi

echo ""
echo "4. 验证 Info.plist 网络权限："
if grep -q "NSAllowsLocalNetworking" Sources/Info.plist; then
    echo "✅ Info.plist 包含网络权限"
    grep -A 3 "NSAppTransportSecurity" Sources/Info.plist
else
    echo "❌ Info.plist 缺少网络权限"
fi
