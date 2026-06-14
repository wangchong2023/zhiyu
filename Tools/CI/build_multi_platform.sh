#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: build_multi_platform.sh
# 脚本功能: 多平台编译验证（iOS / macOS / watchOS），失败时自动汇总错误。
# 用法: ./Tools/CI/build_multi_platform.sh
# ==============================================================================
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"
LOG_DIR="build/multi_platform_logs"
mkdir -p "$LOG_DIR"

# 构建单平台，保存完整日志，失败时提取错误
build_platform() {
  local scheme="$1"
  local dest="$2"
  local label="$3"
  local log_file="$LOG_DIR/${label}.log"

  echo "🔨 验证 ${label} 构建..."
  echo "   日志: ${log_file}"

  set +e
  set -o pipefail
  xcodebuild build \
    -project "${PROJECT}" \
    -scheme "${scheme}" \
    -destination "${dest}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee "$log_file"
  local exit_code=${PIPESTATUS[0]}
  set -e

  if [ $exit_code -ne 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ ${label} 构建失败 (exit=${exit_code})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  编译错误:"
    grep -E "^.*:[0-9]+:[0-9]+: error:" "$log_file" | sort -t: -k1,1 -k2,2n -u || echo "  (未找到标准编译错误)"
    echo ""
    echo "  致命错误:"
    grep -i "fatal error" "$log_file" || echo "  (none)"
    echo ""
    echo "  日志尾部:"
    tail -10 "$log_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return $exit_code
  fi
  echo "  ✅ ${label} 编译通过"
}

build_platform "ZhiYu" "generic/platform=iOS" "iOS"
build_platform "ZhiYuMac" "platform=macOS" "macOS"
build_platform "ZhiYuWatch" "generic/platform=watchOS" "watchOS"

echo ""
echo "✅ 全平台编译验证通过"
