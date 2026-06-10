#!/bin/bash
# build_multi_platform.sh
#
# 功能：多平台编译验证（iOS / macOS / watchOS）
# 用法：./Tools/CI/build_multi_platform.sh
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"

build_platform() {
  local scheme="$1"
  local dest="$2"
  xcodebuild build \
    -project "${PROJECT}" \
    -scheme "${scheme}" \
    -destination "${dest}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    | tail -5
}

echo "🔨 验证 iOS 设备构建..."
build_platform "ZhiYu" "generic/platform=iOS"

echo "🔨 验证 macOS 构建..."
build_platform "ZhiYuMac" "platform=macOS"

echo "🔨 验证 watchOS 构建..."
build_platform "ZhiYuWatch" "generic/platform=watchOS"

echo "✅ 全平台编译验证通过"
