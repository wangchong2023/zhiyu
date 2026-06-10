#!/bin/bash
# run_unit_tests.sh
#
# 功能：构建 + 单元测试 + 覆盖率收集
# 用法：./Tools/CI/run_unit_tests.sh
set -euo pipefail

PROJECT="ZhiYu.xcodeproj"
SCHEME="ZhiYu"
DEST="platform=iOS Simulator,name=iPhone 17 Pro"
DERIVED="build/DerivedData"

set +e
xcodebuild test \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -destination "${DEST}" \
  -only-testing:ZhiYuTests \
  -enableCodeCoverage YES \
  -derivedDataPath "${DERIVED}" \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee build/test_output.log

TEST_EXIT=${PIPESTATUS[0]}
set -e
if [ ${TEST_EXIT} -ne 0 ]; then
  echo "❌ 单元测试失败 (exit=${TEST_EXIT})"
  exit ${TEST_EXIT}
fi
