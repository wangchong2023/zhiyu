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

## 认证与导航系统（2026-05-13 更新）
- **Notebook Hub**: 已实施笔记本工作台，支持 2 列卡片布局。
- **AuthSession**: 引入了全局 `@Observable` 认证会话。
- **个人中心**: 个人设置已集成至右上角头像菜单，取代了底部的 Settings Tab。
- **协议驱动 DI**: AuthService 和 VaultService 已重构为基于协议的注入。

## 待处理
- Notebook Hub 页面视觉优化（支持笔记本封面自定义）
- iCloud 集成真机测试
- Graph 视图按钮布局修复
- 更多服务的协议化重构（Chat, Synthesis 等）