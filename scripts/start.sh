#!/bin/bash
set -euo pipefail

BOOTSTRAP_HOME="/opt/bootstrap-home"
BOOTSTRAP_ZSHRC="$BOOTSTRAP_HOME/.zshrc"
BOOTSTRAP_OMZ="$BOOTSTRAP_HOME/.oh-my-zsh"
SETTINGS_PATH="${HOME}/.local/share/code-server/User/settings.json"
GLOBAL_EXTENSIONS_DIR="/opt/code-server/extensions"
USER_EXTENSIONS_DIR="${HOME}/.local/share/code-server/extensions"

needs_zshrc_restore() {
  if [ ! -f "$HOME/.zshrc" ]; then
    return 0
  fi

  grep -q "zsh-newuser-install" "$HOME/.zshrc"
}

restore_home_shell() {
  mkdir -p "$HOME"

  if [ -d "$BOOTSTRAP_OMZ" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
    cp -a "$BOOTSTRAP_OMZ" "$HOME/.oh-my-zsh"
  fi

  if [ -f "$BOOTSTRAP_ZSHRC" ] && needs_zshrc_restore; then
    cp "$BOOTSTRAP_ZSHRC" "$HOME/.zshrc"
  fi
}

link_extensions_dir() {
  local parent_dir

  if [ ! -d "$GLOBAL_EXTENSIONS_DIR" ]; then
    return 0
  fi

  parent_dir="$(dirname "$USER_EXTENSIONS_DIR")"
  mkdir -p "$parent_dir"

  if [ ! -e "$USER_EXTENSIONS_DIR" ]; then
    ln -s "$GLOBAL_EXTENSIONS_DIR" "$USER_EXTENSIONS_DIR"
  fi
}

write_env_log() {
  local log_path="$HOME/.frontend-env.log"

  echo "frontend environment initialized" > "$log_path"
  echo "node: $(node -v 2>/dev/null || echo missing)" >> "$log_path"
  echo "corepack: $(corepack --version 2>/dev/null || echo missing)" >> "$log_path"
  echo "pnpm: $(pnpm -v 2>/dev/null || echo missing)" >> "$log_path"
  echo "yarn: $(yarn -v 2>/dev/null || echo missing)" >> "$log_path"
  echo "nrm: $(nrm --version 2>/dev/null || echo missing)" >> "$log_path"
  echo "nrm selected: ${NRM_REGISTRY}" >> "$log_path"
  echo "npm registry: $(npm config get registry 2>/dev/null || echo unknown)" >> "$log_path"
}

restore_home_shell

NRM_REGISTRY="${NRM_REGISTRY:-npm}"
DEFAULT_WORKSPACE="${DEFAULT_WORKSPACE:-$HOME/workspace}"
SETUP_MARKER="$HOME/.frontend-env-ready"

mkdir -p "$DEFAULT_WORKSPACE"

sudo dumb-init /usr/sbin/cron

if command -v nrm >/dev/null 2>&1; then
  nrm use "$NRM_REGISTRY" >/dev/null 2>&1 || nrm use npm >/dev/null 2>&1 || true
fi

if [ ! -f "$SETUP_MARKER" ]; then
  write_env_log
  touch "$SETUP_MARKER"
fi

link_extensions_dir

if [ ! -f "$SETTINGS_PATH" ]; then
  mkdir -p "$(dirname "$SETTINGS_PATH")"
  cp /opt/code-config/settings.json "$SETTINGS_PATH"
fi
