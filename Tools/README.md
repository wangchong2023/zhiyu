# ZhiYu 开发者工具箱 (Developer Tools)

本目录包含用于加速 ZhiYu 开发与测试的辅助脚本与工具。

## 目录结构原则

- **长期存在**：对于需要长期维护的工具和脚本，直接放置在 `Tools/` 根目录下。
- **临时使用**：对于一次性或实验性的脚本，放置在 `Tools/Temp/` 目录下，并注意及时清理。
- **文档同步**：每当新增或移动脚本时，必须同步更新本 `README.md`。

## 1. [TODO] 数据库种子工具 (`seed_data.py`)

*规划中的开发者工具，用于在未来的迭代中快速初始化或重建模拟器环境下的测试数据。*

### 种子工具规划功能

- **动态定位**：自动探测当前运行中的 iOS 模拟器路径，无需手动修改代码。
- **数据重建**：一键注入 10+ 个包含复杂双向链接、Markdown 语法的示例页面。
- **环境清理**：支持仅清空数据库而不插入数据。

---

## 2. 模拟服务器 (`MockServer`)

用于在本地模拟远程 API 接口，如插件市场、AI 代理等。

### 模拟服务器核心功能

- **静态资源托管**：托管 `community.json` 等配置文件。
- **API 路由模拟**：默认将 `/api/community` 映射至本地 JSON。

### 模拟服务器使用方法

```bash
# 启动服务器（默认监听 http://localhost:8080）
python3 Tools/MockServer/server.py
```

### 验证接口

启动后访问：[http://localhost:8080/api/community](http://localhost:8080/api/community)

---

## 3. 本地化静态审查工具 (`check_localization.py`)

用于在编译前（Xcode Build Phases）或本地进行国际化翻译架构审查。

### 静态审查核心功能

- **全分表交叉对比**：验证源码中引用的所有 `L10n.XXX.tr` 在对应的 `.xcstrings` 物理分表中真实存在，防止运行时 MISSING 发生。
- **强制架构收口**：严禁业务层直接使用带有隐式 Fallback 危险的 `Localized.tr(key)`，强制要求使用类型安全的 `L10n.XXX.tr`。
- **硬编码中文字符串拦截**：拒绝一切裸露在 UI 中的中文字符串字面量，保障 100% 本地化覆盖率。

### 静态审查使用方法

```bash
# 全局扫描 (通常集成在 Xcode Build Phases 中自动执行)
python3 Tools/check_localization.py
```

---

## 4. 全自动代码覆盖率红线校验熔断工具 (`check_coverage.py`)

用于在持续集成流水线中自动提取并校验单元测试的覆盖率，强加指标红线限制。

### 覆盖率校验核心功能

- **结果集自动提取**：全自动扫描 `build/DerivedData`，动态解析最新生成的 `.xcresult` 测试结果集。
- **领域层精准提纯**：剥离模型与数据表的干扰，专门计算核心领域层 (`Sources/Domain`) 的代码覆盖率。
- **红线熔断拦截**：为领域层覆盖率设置 85% 指标红线，未达标时强制返回错误码以熔断持续集成。

### 覆盖率校验使用方法

```bash
python3 Tools/check_coverage.py
```

---

## 5. 自动化测试运行中枢 (`run_tests.sh`)

自动定位可用模拟器设备，物理执行智宇全量单元与集成测试。

### 自动化测试核心功能

- **智能定位模拟器**：自动解析 `simctl` 列表，智能提取无冲突的 iPhone 17 Pro 模拟器 UDID，规避宿主因多版本系统重名导致的 `destination` 冲突问题。
- **状态感知起机**：优先选择已处于 `Booted` 状态的设备，节省耗时；若未运行，则选取最高 OS 版本的匹配模拟器。
- **物理缓存清理**：自动卸载历史 App 容器，清理 Xcode 编译 DerivedData 缓存，消除脏脏数据干扰。

### 自动化测试使用方法

```bash
# 赋予执行权限
chmod +x Tools/run_tests.sh
# 运行脚本
./Tools/run_tests.sh
```

---

## 6. 自动化快照录制与基准覆盖工具 (`update_snapshots.sh`)

在录制模式下自动运行快照测试，生成并覆盖基准快照图像。

### 快照录制核心功能

- **环境变量与启动参数注入**：自动向测试进程传递 `RECORD_MODE=1` 环境变量与 `-environmentRecordMode` 命令行标志。
- **测试类定向收窄**：使用 `-only-testing:ZhiYuTests/ComponentSnapshots` 机制，精准、高效运行且更新快照测试基准。
- **自动开机挂载**：确保 iPhone 17 Pro 模拟器开机就绪，若关机则执行静默后台拉起。

### 快照录制使用方法

```bash
# 赋予执行权限
chmod +x Tools/update_snapshots.sh
# 运行脚本
./Tools/update_snapshots.sh
```

---

## 7. 存储字段守卫工具 (`check_storage_constants.py`)

用于在编译前（Xcode Build Phases）自动校验整个 `Sources/` 目录下是否包含硬编码的物理数据库表名或列字段名。

### 守卫工具核心功能

- **硬编码物理字段拦截**：检测代码中直接写物理字段名（如 `t.column("created_at")` 或 `t.primaryKey(["id"])`）的情况，强制报错。
- **强制使用 Model 字段**：要求必须通过数据库 Model 实体提供的编译期静态常量（如 `KnowledgePage.Columns.createdAt`）来操作数据库表。
- **硬编码 SQL 检测**：识别在 SQL 执行/查询语句中包含未插值的裸物理表名。

### 守卫工具使用方法

```bash
python3 Tools/check_storage_constants.py
```

---

## 8. 注意事项

- **Python 环境**：建议使用 Python 3.8+，本地运行环境指向 `./env/venv/bin/python3`。
- **权限说明**：在 macOS 上操作模拟器容器路径可能需要全盘访问权限（通常 Terminal 会自动请求）。
- **覆盖率提取依赖**：`check_coverage.py` 强依赖 Xcode 命令行工具中内置 of `xccov` 组件。
- **同步建议**：建议在修改数据库架构（Schema）后，同步更新 `seed_data.py` 中的 `INSERT` 语句。
- **权限授予**：运行 `.sh` 脚本前请确保执行了 `chmod +x`。


