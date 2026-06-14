#!/bin/bash
# ==============================================================================
# 项目名称: ZhiYu (智宇 iOS 客户端)
# 脚本名称: prepare_build_environment.sh
# 脚本功能: 生成 Xcode 工程结构文件，拉取并编译 SPM 包以预热测试与编译环境。
# ==============================================================================
set -euo pipefail

# 1. 常量定义
PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DESTINATION="generic/platform=iOS Simulator"
SPM_CACHE_DIR="${HOME}/.cache/zhiyu-spm"

# 2. 生成 Xcode 项目文件
echo "===> xcodegen generate"
xcodegen generate

# 3. 预热测试依赖环境
echo "===> Build-for-testing (SPM + compile)"
mkdir -p build "$SPM_CACHE_DIR"

set -o pipefail
xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -clonedSourcePackagesDirPath "$SPM_CACHE_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee build/test_compile.log

echo "✅ 编译预热与环境依赖加载就绪"
