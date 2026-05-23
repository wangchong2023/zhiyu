# 智宇 (ZhiYu) 全局代码审计与 SOLID 架构重构计划 (2026-05-23)

为响应项目对于 Clean Code、SOLID 设计原则、KISS 原则、多端解耦及中文注释高覆盖率的要求，我们对项目全部 **436 个 Swift 源文件 (共 58,203 行代码)** 进行了系统性审计，特制定本重构计划。

## 1. 审计核心发现与架构痛点 (Audit Results)

### 1.1 L1-L2 物理层级跨层循环依赖 (Violation of DIP / ISP)
* **现状**：
  - L2 业务功能层的 `IngestService.swift` 直接引用了 L1 基础设施层的 `DocumentProcessorFactory` 及其底层的具体代理处理器。
  - 同时，L1 基础设施层的 `DocumentProcessor.swift` 却依赖并使用了定义在 L2 `IngestService.swift` 中的 `DocumentFormat` 枚举。
* **影响**：
  - 形成了物理目录上的**双向循环依赖**。
  - 违反了《L0-L3 垂直层级反向调用禁止约束表》中“L1 绝不允许调用 L2”、“L2 严禁直接依赖基础设施具体类”的架构红线。

### 1.2 共享状态中心越界与 Extension 崩溃隐患 (Violation of Low Coupling)
* **现状**：
  - 供 watchOS Target 和 WidgetExtension 依赖的 `WidgetAndWatchViews.swift` (Shared 层) 直接实例化并调用了 L3 应用层的 `AppStore`。
  - `AppStore` 极度繁重，通过 `@Inject` 强制加载了完整主 App 所需的数据库写入、LLM 客户端、Search、Settings 等服务。
* **影响**：
  - 由于 Widget 和 Watch 进程启动时没有执行完整的 `ModuleRegistrar.register` 流程，当 `let store = AppStore()` 被构造时，其内部 `@Inject` 解析失败，必然触发 `assertionFailure` / `fatalError` 导致**进程启动即闪退 (Crash-on-launch)**。
  - 这违背了 Shared 层“绝对禁止引用上层具体业务及系统集成能力”的规范。

### 1.3 核心单例持有并发 UI 状态 (Violation of SRP / KISS)
* **现状**：
  - `LLMService` (L1) 作为全局单例，持有了 `isProcessing` 和 `streamingContent` 状态。
* **影响**：
  - 在 macOS 多窗口或并发 Chat 会话场景下，单例状态会导致状态交叉污染。状态应当下沉到各个会话的 `ChatCoordinator` / `ViewModel` 独立维护。

### 1.4 中文注释覆盖率缺失 (Violation of Coding Standards)
* **现状**：
  - 全工程有 44 个文件完全缺失标准中文文件头注释（例如 `L10n` 本地化扩展及部分 UI 视图）。
  - 有 652 个非私有函数缺失 `///` 中文文档注释。

### 1.5 魔鬼值硬编码 (Violation of Clean Code)
* **现状**：
  - 共有 1188 处魔鬼值硬编码。主要表现为 UI 中的间距尺寸（如 8, 12, 16）未走 `DesignSystem` 令牌，以及逻辑层中的硬编码错误代码（如 405, 501）。

---

## 2. 重构设计与实施步骤 (Refactoring Action Items)

### 2.1 第一步：消除循环依赖与 DIP 架构重构
1. **下沉 `DocumentFormat`**：
   - 将 `DocumentFormat` 从 `IngestService.swift` 中抽离，移入底层的 [DocumentFormat.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Core/Base/Constants/DocumentFormat.swift)。
2. **抽象文档提取契约**：
   - 在底层声明 [DocumentExtractionServiceProtocol.swift](file:///Users/constantine/Documents/work/code/projects/ZhiYu/Sources/Core/Base/Protocols/DocumentExtractionServiceProtocol.swift)。
3. **接口化重构基础设施**：
   - 让 `DocumentProcessor.swift` 内部的具体实现转移到 `DocumentExtractionService` 类，遵循上述提取协议，并在 `ModuleRegistrar` 中注册。
4. **业务层注入**：
   - 让 `IngestService` 仅通过 `@Inject private var docExtractor: any DocumentExtractionServiceProtocol` 消费接口，彻底斩断对 `DocumentProcessorFactory` 具体实现的依赖。

### 2.2 第二步：解耦共享视图与多平台 DI 闪退整治
1. **轻量化 watchOS/Widget 启动装配**：
   - 在 `ZhiYuWatchApp.swift` (watchOS) 和 Widget 的 Entry 启动时，调用轻量的 `WatchModuleRegistrar` 注册必要的基础服务，防止 `@Inject` 寻找实例引发的闪退。
2. **重构加载逻辑**：
   - 将 `WatchKnowledgeStatsView` 对 `AppStore` 的直接实例化改写，移除对 `AppStore` 强依赖，仅通过轻量级机制或局部 DI 服务读取最简指标。

### 2.3 第三步：中文注释补全与魔鬼值常量化
1. **文件头补齐**：对 44 个缺失文件头注释的文件补齐作者、功能说明、版本、版权中文信息。
2. **函数注释规范化**：重点为核心业务 Feature/Domain 的公共接口补全 `///` 三斜杠中文参数及返回值说明。
3. **消除硬编码**：
   - 将 Widget 中的 UI 间距尺寸（如 8, 12, 16）重构为 `DesignSystem.tightPadding` / `DesignSystem.medium` 等。
   - 将硬编码整型错误码归拢至各自的强类型 Error 枚举。

---

## 3. 重构前后物理调用依赖对比

```mermaid
graph TD
    subgraph 重构前 (双向物理循环依赖)
        IngestService_Old["IngestService (L2)"] <--> DocumentProcessorFactory_Old["DocumentProcessorFactory (L1)"]
    end

    subgraph 重构后 (单向面向协议依赖)
        IngestService_New["IngestService (L2)"] -->|依赖注入| DocExtractProto["DocumentExtractionServiceProtocol (L0)"]
        DocExtractImpl["DocumentExtractionService (L1)"] -->|实现协议| DocExtractProto
        DocExtractImpl -->|使用| DocFormat["DocumentFormat (L0)"]
        IngestService_New -->|使用| DocFormat
    end

    style DocExtractProto fill:#f9f,stroke:#333,stroke-width:2px
    style DocFormat fill:#bbf,stroke:#333,stroke-width:2px
```

---

## 4. 验证与编译方法 (Verification)

重构后，由于涉及 iOS、macOS Catalyst 和 watchOS 三端，必须确保所有 Scheme 的编译通过。

```bash
# 生成 Xcode 项目
xcodegen generate

# 1. 编译 iOS
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/ios_build.log 2>&1

# 2. 编译 macOS Catalyst
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/mac_build.log 2>&1

# 3. 编译 watchOS
xcodebuild build -project ZhiYu.xcodeproj -scheme ZhiYuWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build/watch_build.log 2>&1

# 4. 运行 XCTest 单元测试
xcodebuild test -project ZhiYu.xcodeproj -scheme ZhiYu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' > build/test_results.log 2>&1
```
