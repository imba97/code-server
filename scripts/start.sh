#!/bin/bash

# 启动定时任务
sudo dumb-init /usr/sbin/crond

# 配置启动 openssh server
# echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true
# echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true
# echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true
# sudo dumb-init /usr/sbin/sshd -D &

# 启动 npc
if [ -n "${NPS_SERVER}" -a -n "${NPS_KEY}" ]; then
    echo "配置 nps..."
    nohup npc -server=${NPS_SERVER} -vkey=${NPS_KEY} -type=tcp &
fi

# 安装 nvm
if [ ! -d ${HOME}/.nvm ]; then
    git clone https://github.com/nvm-sh/nvm.git ${HOME}/.nvm
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
fi

# vscode 配置
cp /opt/code-config/settings.json ${HOME}/.local/share/code-server/User/settings.json

# 自定义环境变量
cat > ${HOME}/.zshrc <<-EOF
# oh-my-zsh
ZSH=/usr/share/oh-my-zsh/
ZSH_THEME="jovial"
plugins=(git)
ZSH_CACHE_DIR=\$HOME/.cache/oh-my-zsh
if [[ ! -d \$ZSH_CACHE_DIR ]]; then
  mkdir -p \$ZSH_CACHE_DIR
fi
source \$ZSH/oh-my-zsh.sh

# code-server workspace
export DEFAULT_WORKSPACE="\$HOME/workspace"
if [[ ! -d \$DEFAULT_WORKSPACE ]]; then
  mkdir -p \$DEFAULT_WORKSPACE
fi

# plugin
[[ -s /etc/profile.d/autojump.zsh ]] && source /etc/profile.d/autojump.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

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
export EDITOR="\$VISUAL"

export NVM_DIR="$HOME/.nvm"
[ -s "\${NVM_DIR}/nvm.sh" ] && \. "\${NVM_DIR}/nvm.sh"
[ -s "\${NVM_DIR}/bash_completion" ] && \. "\${NVM_DIR}/bash_completion"

# load user zshrc
[ -f ${HOME}/.zshrc.user ] && source ${HOME}/.zshrc.user
EOF