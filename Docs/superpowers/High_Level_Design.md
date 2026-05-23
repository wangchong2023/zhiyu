# 智宇 (ZhiYu) - 高级架构设计 (High-Level Design)

本文档阐述了智宇 (ZhiYu) 的核心架构设计理念与垂直切片分层。

## 1. 架构愿景 (Architecture Vision)

智宇遵循 **垂直化功能架构 (Vertical Slices)** 辅以**整洁架构 (Clean Architecture)** 的依赖倒置原则。整个系统按职责的深浅被严格划分为物理上隔离的层次，以此保证 UI 可以被轻松替换，核心业务逻辑可以跨平台 (iOS, macOS, watchOS) 复用，且第三方基础设施 (如 LLM 供应商, 数据库引擎) 能被随时插拔。

## 2. 层次结构 (Layering Strategy)

核心应用被分为 6 个主要层级（L0 - L3），依赖方向必须严格遵守 **自上而下** 或 **依赖反转 (DIP)**。

### 📌 L3 应用层 (App) - `Sources/App/`
- **职责**：应用的生命周期管理，全局环境装配与依赖注入配置。
- **核心组件**：`ZhiYuApp.swift`, 平台相关的启动逻辑。
- **约束**：只能做组装工作，不包含具体的业务逻辑。

### 📌 L2 业务功能层 (Features) - `Sources/Features/`
- **职责**：基于具体业务场景 (UseCase) 进行垂直切割。包含该业务所独有的视图 (Views)、视图模型 (ViewModels) 和本地状态。
- **核心模块**：
  - `CaptureFeature`: 快速捕获与碎片输入。
  - `ChatFeature`: AI 会话与自然语言交互。
  - `KnowledgeBaseFeature`: 知识卡片管理与浏览。
  - `SettingsFeature`: 系统配置与偏好。
- **约束**：**严禁横向相互调用**。一个 Feature 若需要另一个 Feature 的能力，必须通过协调器或共享的服务下沉到 Domain 层解决。

### 📌 L1.5 领域中台层 (Domain) - `Sources/Domain/`
- **职责**：**核心业务大脑**。处理所有不依赖具体 UI 的纯粹业务规则，例如 RAG 的工作流编排、知识页面的领域模型、打分与评估体系。
- **核心组件**：
  - `RAGOrchestrator`: 协调搜索与大模型的 RAG 生成流水线。
  - `Domain/Models/`: 包含 `KnowledgePage`, `PageType`, `ChatSession` 等模型。
  - `Domain/Protocols/`: 供基础设施层实现的跨平台契约协议。
- **约束**：**绝对纯净**。不能 `import SwiftUI`, `UIKit`, `AppKit`。所有平台相关代码必须被抽象为协议。

### 📌 L1 基础设施层 (Infrastructure) - `Sources/Infrastructure/`
- **职责**：实现具体的外部系统交互：本地持久化数据库、向量检索库、第三方 LLM API 请求封装、iCloud 云端同步。
- **核心组件**：
  - `LLMService`: 面向大型语言模型的门面，内部组合 `ChatLLMService`, `IngestLLMService`, `RerankService`。
  - `SQLiteStore` / `GRDB`: 本地知识库的物理存储引擎。
  - `iCloudSyncManager`: iCloud KV 跨设备同步。

### 📌 L0.5 系统集成层 (System) - `Sources/Core/System/`
- **职责**：封装 Apple OS 平台原生的具体能力，如触觉反馈 (Haptics)、文件安全、相机扫描、生物识别。
- **约束**：通过依赖注入暴露给上层使用，实现业务侧与系统 SDK 的隔离。

### 📌 L0 底层基座层 (Base) - `Sources/Core/Base/`
- **职责**：整个系统的基础设施底座，提供诸如全局 DI 容器、基础 DTO 定义、全应用日志打印机制等。
- **核心组件**：
  - `ServiceContainer`: 全局依赖注入的内核。
  - `DTOs`: 模块间的数据传输标准。
  - `Logger`: 全局统一审计日志。

## 3. RAG 数据流设计 (Data Flow for RAG)

ZhiYu 的核心不仅是笔记编辑，而是一个完整的 **Retrieval-Augmented Generation (检索增强生成)** 闭环系统。

1. **摄入 (Ingestion)**:
   - 用户输入碎片文本 -> `KnowledgeBaseFeature` 接收。
   - `IngestLLMService` (LLM) 进行清洗、分类并生成总结和标签。
   - `KnowledgeStore` (SQLite) 对结构化数据落盘，`SearchStore` 对正文进行混合 FTS5 + 向量化嵌入 (Embeddings)。

2. **检索与生成 (Retrieval & Generation)**:
   - 用户在 `ChatFeature` 发起提问。
   - `SearchStore` 执行密集与稀疏混合检索，召回候选 Top-K 节点。
   - `RerankService` 利用轻量级大模型或规则对节点进行相关性重排。
   - `ChatLLMService` 将重排后的 Context 和用户 Query 组装为完整的 Prompt，向 LLM 请求答案，流式吐出至 UI 层。

3. **评估与反馈 (Evaluation)**:
   - 在生成完毕后，`RAGEvaluationService` 会以后台进程的身份通过大模型作为“法官”，针对生成的 **Faithfulness (忠实度)** 与 **Relevance (相关性)** 进行无感打分，并记录到 `GovernanceStore` 以便未来优化提示词和检索策略。

## 4. 可扩展性与演进

- 插件机制 (`PluginRegistry`) 允许未来加入自定义的宏 (Macros) 与 JavaScript 工具。
- `LLMServiceProtocol` 的剥离允许随时接入本地大模型 (如 MLX, CoreML) 替换云端模型，真正实现离线 AI 原生能力。
