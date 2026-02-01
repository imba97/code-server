#!/bin/bash

# 启动定时任务 (Ubuntu/Debian 使用 cron 而非 crond)
sudo dumb-init /usr/sbin/cron

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
