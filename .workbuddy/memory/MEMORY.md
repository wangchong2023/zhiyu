# MEMORY.md - 长期记忆

## 项目背景
- **项目**: ZhiYu (知予) - 知识管理应用，类似 Google NotebookLM
- **技术栈**: SwiftUI 多平台 (iPhone/iPad/Mac)，XcodeGen 管理项目
- **代码路径**: /Users/constantine/Documents/work/code/projects/ZhiYu/

## 用户偏好
- **语言**: 中文交流，技术术语中英混用
- **输出格式**: 结构化（表格、步骤列表、计划文档）
- **工作流**: 发现问题 → 给出详细执行计划(带优先级+估时) → 逐步实施 → 验证测试
- **代码偏好**: 使用编译宏(#if)禁用代码而非注释符号

## 当前关注迭代
1. Graph 视图按钮布局修复（图标颜色一致性+触控区域）
2. Ingest 模块 LazyVGrid 响应式布局（2列自适应）
3. iCloud 功能集成与真机测试
4. 测试覆盖率提升
5. KMStore.ToolItem 缺失 'healthCheck' 成员编译错误
6. iPad 性能监控卡片无法弹出 sheet 的根因排查

## 认证系统设计（已完成）
- 支持登录方式: 微信、手机号、QQ、Apple、Google
- 架构文档: /Users/constantine/Documents/work/code/projects/ZhiYu/Docs/AuthArchitecture.md
- 设计方案: OAuth策略模式 + JWT Token

## 项目结构
- Sources/Shared: 共享视图和组件
- Sources/App: 应用入口
- Features: 功能模块（Auth/NotebookHub/Notebook/Ingest/Graph等）
- Tests: 测试文件
- Docs: 文档

## 待处理
- NotebookHub 页面设计（NotebookLM风格）
- Graph 视图按钮布局修复
- iCloud 集成真机测试