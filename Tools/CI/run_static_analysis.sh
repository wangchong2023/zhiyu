#!/bin/bash
# ==============================================================================
# run_static_analysis.sh
# 集中执行全部 10 项静态分析检查，任何一项失败立即退出
# 用法: ./Tools/CI/run_static_analysis.sh
# ==============================================================================
set -euo pipefail

echo "====== Static Analysis (10 checks) ======"
echo ""

# [1/10] 架构依赖
echo "--- [1/10] Architecture Dependency (L0-L3) ---"
python3 Tools/Gatekeeper/check_architecture_dependency.py

# [2/10] 领域纯净度
echo "--- [2/10] Domain Purity ---"
python3 Tools/Gatekeeper/check_domain_purity.py

# [3/10] DI 测试设置审计
echo "--- [3/10] DI Test Setup Audit ---"
python3 Tools/Gatekeeper/check_test_di_setup.py

# [4/10] 根目录卫生 (临时文件 + 结构)
echo "--- [4/10] Root Hygiene ---"
python3 Tools/Gatekeeper/check_root_hygiene.py

# [5/10] 魔鬼数字/字符串
echo "--- [5/10] Magic Numbers / Strings ---"
python3 Tools/Gatekeeper/check_magic_numbers_v2.py

# [6/10] 分层标记检查
echo "--- [6/10] Layer Markers ---"
bash Tools/Lint/lint_layer_markers.sh

# [7/10] String.Index 越界扫描
echo "--- [7/10] Unsafe String.Index Scan ---"
python3 Tools/Lint/scan_unsafe_string_index.py

# [8/10] 文档完整性 + 配置健康 + ShellCheck
echo "--- [8/10] Docs + Config Integrity + ShellCheck ---"
python3 Tools/Gatekeeper/check_docs_integrity.py
python3 Tools/Gatekeeper/check_configs_integrity.py
bash Tools/CI/run_shellcheck.sh

# [9/10] SPM 完整性校验
echo "--- [9/10] SPM Integrity ---"
bash Tools/CI/verify_spm_integrity.sh

# [10/10] SBOM 生成
echo "--- [10/10] SBOM Generation ---"
python3 Tools/CI/generate_sbom.py
brew install syft 2>/dev/null || true
syft . -o cyclonedx-json=build/syft.cdx.json 2>/dev/null || echo "Syft not available, skipping"
python3 Tools/CI/merge_sbom.py

echo ""
echo "====== Static Analysis PASSED ======"
