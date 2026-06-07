# 开发编码规范

> 状态: 骨架 — 待补充完整编码规范

## 核心规范

- **仅构造器注入 / @Inject** — 禁止直接 ServiceContainer.shared.resolve 在 View 层
- **View 薄层** — 禁止在 View 中注入 Repository，禁止编写业务逻辑
- **Entity → DTO** — 通过 Converter 转换，禁止直接暴露 Entity
- **不可变数据** — 创建新对象，禁止修改已有对象
- **中文注释** — 文件头、公开 API、复杂逻辑处必须中文注释
- **L10n 强制** — 所有用户可见文本必须通过 L10n.模块.属性 访问
- **AppError 工厂** — 统一使用 AppError.xxx() 而非裸 NSError

## 参考

- [swift-coding-style.md](../guides/swift-coding-style.md)
- [config-conventions.md](../guides/config-conventions.md)
- [implementation-patterns.md](../guides/implementation-patterns.md)
