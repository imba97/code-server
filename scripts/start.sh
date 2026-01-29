#!/bin/bash

# 启动定时任务
sudo dumb-init /usr/sbin/crond

# vscode 配置 (仅当不存在时复制)
if [ ! -f "${HOME}/.local/share/code-server/User/settings.json" ]; then
  mkdir -p "${HOME}/.local/share/code-server/User"
  cp /opt/code-config/settings.json "${HOME}/.local/share/code-server/User/settings.json"
fi
