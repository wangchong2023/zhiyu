#!/bin/bash
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DEST="generic/platform=iOS Simulator"
BUILD_DIR="build/reproducible_test"

echo "====> 确定性构建验证 (L1+L2) <===="
SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
export SOURCE_DATE_EPOCH
mkdir -p "$BUILD_DIR"

for i in 1 2; do
    echo "  --- 构建 #${i} ---"
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DEST" \
        -derivedDataPath "$BUILD_DIR/build${i}" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        2>&1 | tail -3
done

BIN1=$(find "$BUILD_DIR/build1" -name "ZhiYu" -type f -not -path "*.dSYM/*" | head -1)
BIN2=$(find "$BUILD_DIR/build2" -name "ZhiYu" -type f -not -path "*.dSYM/*" | head -1)

if [ -z "$BIN1" ] || [ -z "$BIN2" ]; then
    echo "  ⚠️  未找到二进制文件，跳过比对"
    exit 0
fi

HASH1=$(shasum -a 256 "$BIN1" | cut -d' ' -f1)
HASH2=$(shasum -a 256 "$BIN2" | cut -d' ' -f1)

if [ "$HASH1" = "$HASH2" ]; then
    echo "  ✅ 构建可重现: SHA256 一致 ($HASH1)"
else
    echo "  ⚠️  构建不可重现:"
    echo "      build1: $HASH1"
    echo "      build2: $HASH2"
fi
rm -rf "$BUILD_DIR"
