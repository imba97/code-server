#!/bin/bash

# 启动定时任务
sudo /usr/sbin/cron

# 配置启动 openssh server
echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true
echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true
echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true
sudo dumb-init /usr/sbin/sshd -D &

# 启动 npc
if [ -n "${NPS_SERVER}" -a -n "${NPS_KEY}" ]; then
    echo "配置 nps..."
    nohup npc -server=${NPS_SERVER} -vkey=${NPS_KEY} -type=tcp &
fi

if [ ! -f ${HOME}/.oh-my-zsh/oh-my-zsh.sh ]; then
    echo "安装 oh-my-zsh ..."
    rm -rf ${HOME}/.oh-my-zsh
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 安装 zsh 插件
if [ ! -d ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
if [ ! -d ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d ${HOME}/.autojump ]; then
    cp -rf /tmp/autojump ${HOME}/.autojump
fi

# 安装 nvm
if [ ! -d ${HOME}/.nvm ]; then
    git clone https://github.com/nvm-sh/nvm.git ${HOME}/.nvm
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
fi

# vscode 配置
cp /opt/code-config/settings.json ${HOME}/.local/share/code-server/User/settings.json
# vscode 语言
cp /opt/code-config/argv.json ${HOME}/.local/share/code-server/User/argv.json

# 自定义环境变量
cat > ${HOME}/.zshrc <<-EOF
# oh-my-zsh
ZSH=/usr/share/oh-my-zsh/
ZSH_THEME="robbyrussell"
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
[[ -s \${HOME}/.autojump/etc/profile.d/autojump.sh ]] && source \${HOME}/.autojump/etc/profile.d/autojump.sh

# alias
alias cp="cp -i"
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
