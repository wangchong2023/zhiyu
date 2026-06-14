# GitHub 分支保护规则

> 配置日期: 2026-06-14 | 配置方式: GitHub Web UI

## main 分支保护规则

在 `https://github.com/wangchong2023/ZhiYu/settings/branches` 配置：

### Branch name pattern
`main`

### Protect matching branches
- [x] Require a pull request before merging
  - [x] Require approvals: 1
  - [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging
  - Status checks:
    - `ci / lint-and-audit`
    - `ci / test`
    - `ci / multi-platform (iOS)`
- [x] Require conversation resolution before merging
- [x] Do not allow bypassing the above settings
  - [x] Include administrators

## Gitea 等效配置

通过 API 同步:
```bash
curl -X POST "http://localhost:3000/api/v1/repos/constantine/ZhiYu/branch_protections" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "branch_name": "main",
    "enable_push": false,
    "enable_approvals_whitelist": true,
    "approvals_whitelist_username": ["constantine"],
    "required_approvals": 1,
    "enable_status_check": true
  }'
```

## 验证

```bash
# GitHub
gh api repos/wangchong2023/ZhiYu/branches/main/protection

# Gitea
curl http://localhost:3000/api/v1/repos/constantine/ZhiYu/branch_protections
```
