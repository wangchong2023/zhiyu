#!/bin/bash
# inject_version.sh — 注入版本号到 Info.plist（双 CI 通用）
#
# 用法: ./inject_version.sh <info_plist_path>
# 示例: bash Tools/CI/Build/inject_version.sh Sources/Info.plist

set -euo pipefail

PLIST="${1:?用法: $0 <info_plist_path>}"

if [ ! -f "$PLIST" ]; then
    echo "[inject_version] ERROR: Info.plist 不存在: $PLIST"
    exit 1
fi

# ── 1. SemVer：从最近祖先 git tag 提取 ──
TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$TAG" ]; then
    VERSION="${TAG#v}"          # v1.2.3 → 1.2.3
else
    VERSION="0.0.0"             # 无 tag 时 fallback（纯数字，通过 App Store 合规检查）
fi

# ── 2. 构建号：提交总数（跨 CI 系统一致）──
BUILD=$(git rev-list --count HEAD)

# ── 3. 短哈希：精确回溯 commit ──
HASH=$(git rev-parse --short HEAD)

# ── 4. 构建时间：ISO 8601 格式（北京时间）──
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── 4. 写入 Info.plist ──
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PLIST"

# 自定义键 GIT_SHORT_HASH（Info.plist 无标准字段）
if /usr/libexec/PlistBuddy -c "Print :GIT_SHORT_HASH" "$PLIST" &>/dev/null; then
    /usr/libexec/PlistBuddy -c "Set :GIT_SHORT_HASH $HASH" "$PLIST"
else
    /usr/libexec/PlistBuddy -c "Add :GIT_SHORT_HASH string $HASH" "$PLIST"
fi

# 自定义键 BUILD_TIMESTAMP（ISO 8601 构建时间）
if /usr/libexec/PlistBuddy -c "Print :BUILD_TIMESTAMP" "$PLIST" &>/dev/null; then
    /usr/libexec/PlistBuddy -c "Set :BUILD_TIMESTAMP $BUILD_TIME" "$PLIST"
else
    /usr/libexec/PlistBuddy -c "Add :BUILD_TIMESTAMP string $BUILD_TIME" "$PLIST"
fi

echo "[inject_version] CFBundleShortVersionString=$VERSION  CFBundleVersion=$BUILD  GIT_SHORT_HASH=$HASH  BUILD_TIMESTAMP=$BUILD_TIME"
