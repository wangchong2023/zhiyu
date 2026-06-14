# CI 故障演练日志

> 每月第一个周一执行，记录演练结果与改进项。

| 日期 | 场景 | 操作 | 结果 | 改进项 |
|------|------|------|------|--------|
| - | - | - | - | - |

## 演练场景清单

### 1. 依赖不可用
- **操作:** `rm -rf ~/.cache/zhiyu-spm`
- **预期:** CI 能从远程重新下载 SPM 依赖，构建成功
- **异常处理:** CI 超时或网络错误 → 检查 SPM 镜像配置

### 2. 磁盘满
- **操作:** `dd if=/dev/zero of=build/fill.tmp bs=1m count=1024`
- **预期:** CI 超时机制生效，飞书告警触发
- **清理:** `rm build/fill.tmp`

### 3. Agent 宕机
- **操作:** `launchctl unload ~/Library/LaunchAgents/com.zhiyu.woodpecker-agent.plist`
- **预期:** Gitea Webhook 重试机制正常
- **恢复:** `launchctl load ~/Library/LaunchAgents/com.zhiyu.woodpecker-agent.plist`
