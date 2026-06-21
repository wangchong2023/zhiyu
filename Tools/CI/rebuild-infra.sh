#!/bin/bash
# =============================================================================
# 文件名: rebuild-all.sh
# 描述:   本地 CI/CD 基础设施全量重建脚本
#         涵盖 Nexus、Gitea、Woodpecker Server、Woodpecker Agent 的
#         镜像拉取、打标、推送到 Docker Hub 及全量容器启动
# 用法:
#   DOCKERHUB_USERNAME=yourname ./rebuild-all.sh          # 完整流程
#   DOCKERHUB_USERNAME=yourname ./rebuild-all.sh --push-only   # 仅推送，不重启服务
#   DOCKERHUB_USERNAME=yourname ./rebuild-all.sh --start-only  # 仅启动服务
#   DOCKERHUB_USERNAME=yourname ./rebuild-all.sh --build-only  # 仅构建镜像
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# ★ 可配置区域 —— 根据实际情况修改以下变量
# -----------------------------------------------------------------------------

# Woodpecker Agent 版本（需与 docker-compose.yml 一致）
WOODPECKER_VERSION="v3.15.0"

# 各镜像版本
GITEA_VERSION="1.26.1"
NEXUS_IMAGE="sonatype/nexus3:latest"
PLUGIN_GIT_VERSION="2.9.1"

# 项目路径（显式指定，参考 NEXUS_DIR 风格）
SCRIPT_DIR="/Users/constantine/devs/rnd-cicd/tools"
RNDCICD_DIR="${SCRIPT_DIR}"
NEXUS_DIR="/Users/constantine/devs/rnd-cicd/nexus"

# Woodpecker Agent GitHub release 下载地址（Linux ARM64）
WP_AGENT_DOWNLOAD_URL="https://github.com/woodpecker-ci/woodpecker/releases/download/${WOODPECKER_VERSION}/woodpecker-agent_linux_arm64.tar.gz"
WP_AGENT_LOCAL_BINARY="${SCRIPT_DIR}/woodpecker-agent"
WP_AGENT_BACKUP="${SCRIPT_DIR}/woodpecker-agent.macos.bak"

# -----------------------------------------------------------------------------
# 使用帮助
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF

用法:
  DOCKERHUB_USERNAME=<用户名> $(basename "$0") [选项]

描述:
  本地 CI/CD 基础设施全量重建工具。
  覆盖 Nexus、Gitea、Woodpecker Server/Agent 的镜像构建、推送与服务启动。
  所有配置通过同目录下的 .env 文件管理（参考 .env.example）。

运行模式 (默认: full):
  （无参数）           完整流程：下载二进制 → 构建镜像 → 推送 Docker Hub
                       → 更新 compose → 启动服务 → 健康检查 → 注册 Secrets
  --push-only          仅构建并推送所有镜像到 Docker Hub，不启动服务
  --build-only         仅下载 woodpecker-agent 二进制并构建镜像，不推送
  --start-only         仅更新 compose 文件并启动所有服务（跳过镜像构建）
  --help, -h           显示此帮助信息

必需环境变量:
  DOCKERHUB_USERNAME   Docker Hub 用户名（也可在 .env 中配置）

可选环境变量（优先读取 .env，也可临时覆盖）:
  GITEA_VERSION        Gitea 版本号         (默认: ${GITEA_VERSION})
  WOODPECKER_VERSION   Woodpecker 版本号    (默认: ${WOODPECKER_VERSION})
  PLUGIN_GIT_VERSION   plugin-git 版本号    (默认: ${PLUGIN_GIT_VERSION})
  WOODPECKER_API_TOKEN Woodpecker API Token（用于自动注册 Secrets）
  DEPLOY_SSH_USER      SSH 部署用户名       (默认: parallels)
  DEPLOY_SSH_PASSWORD  SSH 部署密码
  WOODPECKER_REPOS     需注册 Secrets 的仓库（逗号分隔）
  DEPLOY_HOST          部署目标主机         (默认: 10.211.55.4)

关键文件:
  .env                 本地敏感配置（不提交 Git）
  .env.example         配置模板（可提交 Git）
  Dockerfile           构建 woodpecker-agent ARM64 fixed 镜像
  docker-compose.yml   Gitea + Woodpecker 服务编排
  ${NEXUS_DIR}/docker-compose.yml
                       Nexus 服务编排

示例:
  # 完整重建（从 .env 读取用户名）
  source .env && DOCKERHUB_USERNAME=\$DOCKERHUB_USERNAME ./$(basename "$0")

  # 仅推送镜像（不重启服务）
  DOCKERHUB_USERNAME=myname ./$(basename "$0") --push-only

  # 仅启动服务（镜像已存在时）
  DOCKERHUB_USERNAME=myname ./$(basename "$0") --start-only

  # 升级 Woodpecker 版本后重建
  DOCKERHUB_USERNAME=myname WOODPECKER_VERSION=v3.16.0 ./$(basename "$0")

EOF
  exit 0
}

# -----------------------------------------------------------------------------
# 参数解析
# -----------------------------------------------------------------------------
MODE="full"  # full | push-only | start-only | build-only
for arg in "$@"; do
  case "$arg" in
    --push-only)  MODE="push-only" ;;
    --start-only) MODE="start-only" ;;
    --build-only) MODE="build-only" ;;
    --help|-h)    usage ;;
    *)
      echo "未知参数: $arg"
      echo "运行 $(basename "$0") --help 查看帮助"
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------------
# 工具函数
# -----------------------------------------------------------------------------

# 带颜色的日志输出
log_info()    { echo -e "\033[0;36m[INFO]\033[0m  $*"; }
log_success() { echo -e "\033[0;32m[OK]\033[0m    $*"; }
log_warn()    { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
log_step()    { echo -e "\n\033[1;34m══════ $* ══════\033[0m"; }

# 拉取镜像 → 打标为 Docker Hub 路径 → 推送
mirror_image() {
  local src="$1"       # 源镜像，如 gitea/gitea:1.26.1
  local dst_tag="$2"   # 目标 tag，如 gitea:1.26.1（会自动加 $DOCKERHUB_USERNAME/ 前缀）
  local dst="${DOCKERHUB_USERNAME}/${dst_tag}"

  log_info "拉取: ${src}"
  docker pull "${src}"

  log_info "打标: ${src} → ${dst}"
  docker tag "${src}" "${dst}"

  log_info "推送: ${dst}"
  docker push "${dst}"

  log_success "完成: ${dst}"
}

# -----------------------------------------------------------------------------
# Step 0: 前置检查
# -----------------------------------------------------------------------------
check_prerequisites() {
  log_step "前置检查"

  # 检查 DOCKERHUB_USERNAME
  if [ -z "${DOCKERHUB_USERNAME:-}" ]; then
    log_error "未设置 DOCKERHUB_USERNAME，请通过环境变量传入，例如："
    log_error "  DOCKERHUB_USERNAME=yourname ./rebuild-all.sh"
    exit 1
  fi
  log_success "DOCKERHUB_USERNAME = ${DOCKERHUB_USERNAME}"

  # 检查 Docker 守护进程
  if ! docker info > /dev/null 2>&1; then
    log_error "Docker 守护进程未启动，请先打开 Docker Desktop！"
    exit 1
  fi
  log_success "Docker 守护进程正常"

  # 检查 Docker Hub 登录（通过尝试 token 验证）
  log_info "验证 Docker Hub 登录状态..."
  if ! docker pull hello-world > /dev/null 2>&1; then
    log_warn "无法拉取测试镜像，尝试交互式登录..."
    docker login
  fi
  log_success "Docker Hub 登录有效"
}

# -----------------------------------------------------------------------------
# Step 1: 下载并校验 Linux ARM64 Woodpecker Agent 二进制
# -----------------------------------------------------------------------------
prepare_agent_binary() {
  log_step "Step 1: 准备 Linux ARM64 woodpecker-agent 二进制"

  # 判断当前二进制是否为 Linux ELF（即正确格式）
  if [ -f "${WP_AGENT_LOCAL_BINARY}" ]; then
    FILE_TYPE=$(file "${WP_AGENT_LOCAL_BINARY}" | tr '[:upper:]' '[:lower:]')
    if echo "${FILE_TYPE}" | grep -q "elf.*arm"; then
      log_success "已存在 Linux ARM64 二进制，跳过下载"
      return 0
    else
      log_warn "当前 woodpecker-agent 为 macOS 格式，备份后重新下载..."
      mv "${WP_AGENT_LOCAL_BINARY}" "${WP_AGENT_BACKUP}"
    fi
  fi

  log_info "从 GitHub 下载 Linux ARM64 二进制: ${WP_AGENT_DOWNLOAD_URL}"
  TMP_TAR="/tmp/wp-agent-linux-arm64.tar.gz"
  curl -fsSL -o "${TMP_TAR}" "${WP_AGENT_DOWNLOAD_URL}"
  cd /tmp && tar xzf "${TMP_TAR}"
  cp /tmp/woodpecker-agent "${WP_AGENT_LOCAL_BINARY}"
  chmod +x "${WP_AGENT_LOCAL_BINARY}"
  cd "${SCRIPT_DIR}"

  # 再次校验
  FILE_TYPE=$(file "${WP_AGENT_LOCAL_BINARY}" | tr '[:upper:]' '[:lower:]')
  if ! echo "${FILE_TYPE}" | grep -q "elf.*arm"; then
    log_error "下载的二进制格式不正确: ${FILE_TYPE}"
    exit 1
  fi
  log_success "Linux ARM64 二进制就绪 ($(ls -lh "${WP_AGENT_LOCAL_BINARY}" | awk '{print $5}'))"
}

# -----------------------------------------------------------------------------
# Step 2: 构建 woodpecker-agent:fixed 镜像
# -----------------------------------------------------------------------------
build_agent_image() {
  log_step "Step 2: 构建 woodpecker-agent:${WOODPECKER_VERSION}-fixed 镜像"

  local image_tag="${DOCKERHUB_USERNAME}/woodpecker-agent:${WOODPECKER_VERSION}-fixed"
  docker build \
    --platform linux/arm64 \
    -t "${image_tag}" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    "${SCRIPT_DIR}"

  log_success "构建成功: ${image_tag}"
}

# -----------------------------------------------------------------------------
# Step 3: 镜像拉取、打标、推送到 Docker Hub
# -----------------------------------------------------------------------------
push_all_images() {
  log_step "Step 3: 拉取官方镜像并推送至 Docker Hub"

  # 3.1 Gitea
  mirror_image "gitea/gitea:${GITEA_VERSION}" "gitea:${GITEA_VERSION}"

  # 3.2 Woodpecker Server
  mirror_image "woodpeckerci/woodpecker-server:${WOODPECKER_VERSION}" \
               "woodpecker-server:${WOODPECKER_VERSION}"

  # 3.3 plugin-git（Clone 步骤专用镜像）
  mirror_image "woodpeckerci/plugin-git:${PLUGIN_GIT_VERSION}" \
               "plugin-git:${PLUGIN_GIT_VERSION}"

  # 3.4 Nexus
  mirror_image "${NEXUS_IMAGE}" "nexus3:latest"

  # 3.5 推送 woodpecker-agent-fixed（由 Step 2 构建）
  log_info "推送 woodpecker-agent:${WOODPECKER_VERSION}-fixed..."
  docker push "${DOCKERHUB_USERNAME}/woodpecker-agent:${WOODPECKER_VERSION}-fixed"
  log_success "完成: ${DOCKERHUB_USERNAME}/woodpecker-agent:${WOODPECKER_VERSION}-fixed"
}

# -----------------------------------------------------------------------------
# Step 4: 更新 docker-compose.yml 中的镜像地址
# -----------------------------------------------------------------------------
update_compose_files() {
  log_step "Step 4: 更新 docker-compose.yml 镜像地址"

  # ── rnd-cicd docker-compose.yml ──
  local CICD_COMPOSE="${RNDCICD_DIR}/docker-compose.yml"
  cp "${CICD_COMPOSE}" "${CICD_COMPOSE}.bak"

  python3 - <<PYEOF
import re

with open('${CICD_COMPOSE}', 'r') as f:
    content = f.read()

dh = '${DOCKERHUB_USERNAME}'
ver = '${WOODPECKER_VERSION}'
git_ver = '${GITEA_VERSION}'
pg_ver = '${PLUGIN_GIT_VERSION}'

# 替换 gitea 镜像
content = re.sub(r'image:\s*gitea/gitea:[^\s]+',
                 f'image: {dh}/gitea:{git_ver}', content)

# 替换 woodpecker-server 镜像
content = re.sub(r'image:\s*woodpeckerci/woodpecker-server:[^\s]+',
                 f'image: {dh}/woodpecker-server:{ver}', content)

# 替换 woodpecker-agent 镜像（包含旧 Registry 路径和 Docker Hub 路径）
content = re.sub(r'image:\s*(?:10\.211\.55\.2:5001/)?(?:[^/]+/)?woodpecker-agent:[^\s]+',
                 f'image: {dh}/woodpecker-agent:{ver}-fixed', content)

# 替换所有 plugin-git 引用（包含旧 Registry 路径）
content = re.sub(r'(?:10\.211\.55\.2:5001/woodpeckerci/|woodpeckerci/|[^/\s]+/)plugin-git:[^\s]+',
                 f'{dh}/plugin-git:{pg_ver}', content)

with open('${CICD_COMPOSE}', 'w') as f:
    f.write(content)
print('  rnd-cicd docker-compose.yml 已更新')
PYEOF

  # ── nexus docker-compose.yml ──
  local NEXUS_COMPOSE="${NEXUS_DIR}/docker-compose.yml"
  cp "${NEXUS_COMPOSE}" "${NEXUS_COMPOSE}.bak"

  python3 - <<PYEOF2
import re
with open('${NEXUS_COMPOSE}', 'r') as f:
    content = f.read()

dh = '${DOCKERHUB_USERNAME}'

# 替换 nexus 镜像
content = re.sub(r'image:\s*sonatype/nexus3:[^\s]+',
                 f'image: {dh}/nexus3:latest', content)

with open('${NEXUS_COMPOSE}', 'w') as f:
    f.write(content)
print('  nexus docker-compose.yml 已更新')
PYEOF2

  log_success "docker-compose.yml 更新完成（原始文件已备份为 .bak）"
}

# -----------------------------------------------------------------------------
# Step 5: 启动所有服务
# -----------------------------------------------------------------------------
start_services() {
  log_step "Step 5: 启动所有服务"

  # 启动 Nexus
  log_info "启动 Nexus..."
  docker compose -f "${NEXUS_DIR}/docker-compose.yml" up -d
  log_success "Nexus 已启动"

  # 启动 Gitea + Woodpecker
  log_info "启动 Gitea + Woodpecker..."
  docker compose -f "${RNDCICD_DIR}/docker-compose.yml" up -d
  log_success "Gitea + Woodpecker 已启动"
}

# -----------------------------------------------------------------------------
# Step 6: 健康检查
# -----------------------------------------------------------------------------
health_check() {
  log_step "Step 6: 服务健康验证"

  log_info "等待 10 秒让服务完成初始化..."
  sleep 10

  echo ""
  echo "── 容器状态 ──────────────────────────────────"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo ""

  local ALL_OK=true

  check_url() {
    local name="$1"
    local url="$2"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
    if [ "${code}" = "200" ] || [ "${code}" = "301" ] || [ "${code}" = "302" ]; then
      log_success "${name}: HTTP ${code} ✅  (${url})"
    else
      log_warn  "${name}: HTTP ${code} ⚠️  (${url}) — 可能仍在启动中"
      ALL_OK=false
    fi
  }

  check_url "Gitea"      "http://localhost:3000"
  check_url "Woodpecker" "http://localhost:8000"
  check_url "Nexus"      "http://localhost:8081"

  echo ""
  if [ "${ALL_OK}" = true ]; then
    log_success "所有服务均已就绪 🎉"
  else
    log_warn "部分服务尚未就绪，请稍候后手动验证（大型服务如 Nexus 启动需较长时间）"
  fi
}

# -----------------------------------------------------------------------------
# Step 7: 向 Woodpecker 注册 Pipeline SSH Secrets
# 依赖: WOODPECKER_API_TOKEN, DEPLOY_SSH_USER, DEPLOY_SSH_PASSWORD, WOODPECKER_REPOS
# -----------------------------------------------------------------------------
register_woodpecker_secrets() {
  log_step "Step 7: 自动注册 Woodpecker Pipeline Secrets"

  # 检查必要变量
  if [ -z "${WOODPECKER_API_TOKEN:-}" ]; then
    log_warn "WOODPECKER_API_TOKEN 未设置，跳过 Secrets 注册"
    log_warn "请在 .env 中配置 WOODPECKER_API_TOKEN 并重运行"
    return 0
  fi

  local WP_CLI="${SCRIPT_DIR}/woodpecker-cli"
  if [ ! -f "${WP_CLI}" ]; then
    log_warn "woodpecker-cli 未找到（期望路径: ${WP_CLI})，跳过 Secrets 注册"
    return 0
  fi

  local REPOS="${WOODPECKER_REPOS:-constantine/ZhiYu-Backend,constantine/ZhiYu}"
  local SSH_USER="${DEPLOY_SSH_USER:-parallels}"
  local SSH_PASS="${DEPLOY_SSH_PASSWORD:-}"
  local NACOS_PASS="${WOODPECKER_NACOS_PASSWORD:-nacos}"

  export WOODPECKER_SERVER=http://localhost:8000
  export WOODPECKER_TOKEN="${WOODPECKER_API_TOKEN}"

  # 等待 Woodpecker 服务完全启动
  log_info "Woodpecker 启动中，等待 15 秒..."
  sleep 15

  # 逐个仓库注册 secrets
  IFS=',' read -ra REPO_LIST <<< "${REPOS}"
  for repo in "${REPO_LIST[@]}"; do
    repo="$(echo ${repo} | tr -d ' ')"
    log_info "仓库: ${repo}"

    # 删除旧 secrets（忽略错误）
    "${WP_CLI}" repo secret rm --repository "${repo}" --name ssh_user 2>/dev/null || true
    "${WP_CLI}" repo secret rm --repository "${repo}" --name ssh_password 2>/dev/null || true
    "${WP_CLI}" repo secret rm --repository "${repo}" --name nacos_password 2>/dev/null || true

    # 注册 ssh_user
    if "${WP_CLI}" repo secret add \
        --repository "${repo}" \
        --name ssh_user --value "${SSH_USER}" \
        --event push --event pull_request --event tag 2>/dev/null; then
      log_success "  ssh_user → ${repo}"
    else
      log_warn "  ssh_user 注册失败: ${repo}（请检查 WOODPECKER_API_TOKEN 是否有效）"
    fi

    # 注册 ssh_password
    if [ -n "${SSH_PASS}" ]; then
      if "${WP_CLI}" repo secret add \
          --repository "${repo}" \
          --name ssh_password --value "${SSH_PASS}" \
          --event push --event pull_request --event tag 2>/dev/null; then
        log_success "  ssh_password → ${repo}"
      else
        log_warn "  ssh_password 注册失败: ${repo}"
      fi
    else
      log_warn "  DEPLOY_SSH_PASSWORD 未设置，跳过 ssh_password"
    fi

    # 注册 nacos_password
    if "${WP_CLI}" repo secret add \
        --repository "${repo}" \
        --name nacos_password --value "${NACOS_PASS}" \
        --event push --event pull_request --event tag 2>/dev/null; then
      log_success "  nacos_password → ${repo}"
    else
      log_warn "  nacos_password 注册失败: ${repo}"
    fi
  done

  log_success "Woodpecker Secrets 注册完成"
}

# -----------------------------------------------------------------------------
# 主流程
# -----------------------------------------------------------------------------
echo ""
echo -e "\033[1;35m╔══════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;35m║  🚀 本地 CI/CD 基础设施全量重建工具               ║\033[0m"
echo -e "\033[1;35m║     Nexus + Gitea + Woodpecker                   ║\033[0m"
echo -e "\033[1;35m╚══════════════════════════════════════════════════╝\033[0m"
echo ""
log_info "模式: ${MODE} | Docker Hub 用户名: ${DOCKERHUB_USERNAME:-<未设置>}"

case "${MODE}" in
  full)
    check_prerequisites
    prepare_agent_binary
    build_agent_image
    push_all_images
    update_compose_files
    start_services
    health_check
    register_woodpecker_secrets
    ;;
  push-only)
    check_prerequisites
    prepare_agent_binary
    build_agent_image
    push_all_images
    log_success "镜像推送完成，跳过服务启动。"
    ;;
  build-only)
    check_prerequisites
    prepare_agent_binary
    build_agent_image
    log_success "镜像构建完成。"
    ;;
  start-only)
    check_prerequisites
    update_compose_files
    start_services
    health_check
    ;;
esac

echo ""
echo -e "\033[1;32m════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;32m  ✅ 全量重建完成！\033[0m"
echo -e "\033[1;32m     Gitea:      http://localhost:3000\033[0m"
echo -e "\033[1;32m     Woodpecker: http://localhost:8000\033[0m"
echo -e "\033[1;32m     Nexus:      http://localhost:8081\033[0m"
echo -e "\033[1;32m════════════════════════════════════════════════════\033[0m"
echo ""
