# 基础设施配置

> 状态: 骨架 — 待补充 Nacos/Redis/MySQL 配置详情

## 当前基础设施

| 组件 | 用途 | 备注 |
|------|------|------|
| SQLite (GRDB) | 主存储 | 本地知识库 + FTS5 全文搜索 |
| UserDefaults | 轻量配置 | 服务器列表、用户偏好 |
| Keychain | 密钥存储 | API Key、JWT Token |
| iCloud (CloudKit) | 跨设备同步 | LWW 冲突解决 |
