#!/bin/bash
set -euo pipefail

if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

export PATH="$HOME/.nix-profile/bin:$PATH"

NRM_REGISTRY="${NRM_REGISTRY:-npm}"
DEFAULT_WORKSPACE="${DEFAULT_WORKSPACE:-$HOME/workspace}"
SETUP_MARKER="$HOME/.frontend-env-ready"

mkdir -p "$DEFAULT_WORKSPACE"

# 启动定时任务 (Ubuntu/Debian 使用 cron 而非 crond)
sudo dumb-init /usr/sbin/cron

# 前端环境初始化（可重复执行）
if command -v nrm >/dev/null 2>&1; then
  nrm use "$NRM_REGISTRY" >/dev/null 2>&1 || nrm use npm >/dev/null 2>&1 || true
fi

if [ ! -f "$SETUP_MARKER" ]; then
  {
    echo "frontend environment initialized"
    echo "node: $(node -v 2>/dev/null || echo missing)"
    echo "pnpm: $(pnpm -v 2>/dev/null || echo missing)"
    echo "nrm: $(nrm --version 2>/dev/null || echo missing)"
    echo "nrm selected: ${NRM_REGISTRY}"
    echo "npm registry: $(npm config get registry 2>/dev/null || echo unknown)"
  } > "$HOME/.frontend-env.log"
  touch "$SETUP_MARKER"
fi

# 安装 VSCode 扩展（仅首次）
MARKER="$HOME/.extensions-installed"
if [ ! -f "$MARKER" ] && [ -d /opt/extensions ]; then
  echo "Installing VSCode extensions..."
  for vsix in /opt/extensions/*.vsix; do
    [ -f "$vsix" ] && code-server --install-extension "$vsix" || true
  done
  touch "$MARKER"
fi

# vscode 配置 (仅当不存在时复制)
if [ ! -f "${HOME}/.local/share/code-server/User/settings.json" ]; then
  mkdir -p "${HOME}/.local/share/code-server/User"
  cp /opt/code-config/settings.json "${HOME}/.local/share/code-server/User/settings.json"
fi
