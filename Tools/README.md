# ZhiYu 开发者工具箱 (Developer Tools)

本目录包含用于 ZhiYu 开发、测试与质量保障的辅助脚本与工具。

## 目录结构

```
Tools/
├── Gatekeeper/     # 编译门禁脚本（project.yml preBuildScripts 引用）
├── CI/             # CI 流水线脚本（.github/workflows 引用）
├── Lint/           # 代码质量检查（手动执行）
├── Mock/           # Mock 服务器 + 端到端测试
├── Plugins/        # 插件 SDK、示例源文件、测试工具
├── Utils/          # 通用辅助脚本
└── README.md
```

- **新增脚本**：按用途放入对应子目录。
- **文档同步**：新增或移动脚本后，必须同步更新本 `README.md`。

---

## Gatekeeper — 编译门禁

需在 Xcode Build Phases 中以 `python3 Tools/Gatekeeper/<script>.py` 形式引用。

| 脚本 | 功能 |
|------|------|
| `check_domain_purity.py` | 领域层纯净度检查 |
| `check_localization.py` | 硬编码中文 + 违规 tr() 调用拦截 |
| `check_storage_constants.py` | 数据库物理表名/字段名硬编码拦截 |
| `check_magic_numbers_v2.py` | 魔鬼数字扫描（颜色/尺寸/数值） |
| `check_hardcoded_secrets.py` | 硬编码密钥/Token/IP 扫描 |

---

## Mock — 模拟服务器与测试

### 启动插件市场 Mock 服务器

```bash
python3 Tools/Mock/MockServer/server.py
```

默认监听 `http://localhost:8080`。

### 运行 E2E 测试

```bash
python3 Tools/Mock/test_plugin_e2e.py
```

### 运行综合测试套件

```bash
./Tools/Plugins/test_plugin_and_model_features.sh
```

---

## Utils — 辅助脚本

### 快照录制

```bash
./Tools/Utils/update_snapshots.sh
```

### CI 测试进度

```bash
./Tools/CI/ci-test-progress.sh
```

---

## 注意事项

- **Python 环境**：使用系统 `python3`（macOS 自带或 Homebrew 安装）。
- **权限**：`.sh` 脚本首次使用前需 `chmod +x`。
- **覆盖率工具**：`check_coverage.py` 依赖 Xcode `xccov` 组件。
