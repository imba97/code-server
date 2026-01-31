{ oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, pkgs }:

# 生成 .zshrc 配置文件
{
  zshConfig = pkgs.writeText ".zshrc" ''
    # oh-my-zsh (由 Nix 管理)
    ZSH=${oh-my-zsh}/share/oh-my-zsh
    ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
    ZSH_THEME="spaceship"
    plugins=(git)
    ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
    if [[ ! -d $ZSH_CACHE_DIR ]]; then
      mkdir -p $ZSH_CACHE_DIR
    fi
    source $ZSH/oh-my-zsh.sh

    # workspace
    export DEFAULT_WORKSPACE="$HOME/workspace"
    if [[ ! -d $DEFAULT_WORKSPACE ]]; then
      mkdir -p $DEFAULT_WORKSPACE
    fi

    # plugins
    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # alias
    alias ll="ls -l --color=auto"
    alias ls="ls --color=auto"
    alias cp="cp -i"
    alias mv="mv -i"
    alias rm="trash"
    export HIST_STAMPS="yyyy-mm-dd"
    export VISUAL=vim
    export EDITOR="$VISUAL"

    # Nix
    [ -f ~/.nix-profile/etc/profile.d/nix.sh ] && source ~/.nix-profile/etc/profile.d/nix.sh || true
    [ -f $HOME/.zshrc.user ] && source $HOME/.zshrc.user
  '';
}
