# Zsh 配置生成
# 接收 oh-my-zsh 相关包作为参数
{
  pkgs,
  oh-my-zsh,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
}:
pkgs.writeText ".zshrc" ''
  # oh-my-zsh
  export ZSH=${oh-my-zsh}/share/oh-my-zsh
  ZSH_THEME="jovial"
  plugins=(git)
  ZSH_CACHE_DIR=$$HOME/.cache/oh-my-zsh
  if [[ ! -d $$ZSH_CACHE_DIR ]]; then
    mkdir -p $$ZSH_CACHE_DIR
  fi
  source $$ZSH/oh-my-zsh.sh

  # code-server workspace
  export DEFAULT_WORKSPACE="$$HOME/workspace"
  if [[ ! -d $$DEFAULT_WORKSPACE ]]; then
    mkdir -p $$DEFAULT_WORKSPACE
  fi

  # plugin (使用 Nix 包路径)
  source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

  # 主题 (运行时下载)
  mkdir -p $$ZSH/custom/themes
  [ -f $$ZSH/custom/themes/jovial.zsh-theme ] || curl -sSL https://raw.githubusercontent.com/zthxxx/jovial/master/jovial.zsh-theme -o $$ZSH/custom/themes/jovial.zsh-theme

  # alias
  alias ll="ls -l --color=auto"
  alias ls="ls --color=auto"
  alias cp="cp -i"
  alias mv="mv -i"
  alias rm="trash"

  # history show timeline
  export HIST_STAMPS="yyyy-mm-dd"

  # default editor
  export VISUAL=vim
  export EDITOR="$$VISUAL"

  # Nix 环境 (如果存在则加载)
  [ -f ~/.nix-profile/etc/profile.d/nix.sh ] && source ~/.nix-profile/etc/profile.d/nix.sh || true

  # load user zshrc
  [ -f $$HOME/.zshrc.user ] && source $$HOME/.zshrc.user
''
