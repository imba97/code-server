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

# 安装 nodejs
nvm install 16.18.1
nvm use 16.18.1
# npm 工具
npm install --global pnpm

# 自定义环境变量
cat >${HOME}/.zshrc <<-EOF
# oh-my-zsh
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source \$ZSH/oh-my-zsh.sh

# plugin
[[ -s \${HOME}/.autojump/etc/profile.d/autojump.sh ]] && source \${HOME}/.autojump/etc/profile.d/autojump.sh

# alias
alias cp="cp -i"
alias rm="trash"
alias cat="batcat"

# completion
which helm &> /dev/null && source <(helm completion zsh)
which kubectl &> /dev/null && source <(kubectl completion zsh)
which k9s &> /dev/null && source <(k9s completion zsh)

# env
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
export GOPATH=~/golang
export PATH=\$GOPATH/bin:\$GOROOT/bin:\$HOME/.local/bin:\$PATH:/usr/sbin:/sbin

# history show timeline
export HIST_STAMPS="yyyy-mm-dd"

# default editor
export VISUAL=vim
export EDITOR="\$VISUAL"

# load user zshrc
[ -f ${HOME}/.zshrc.user ] && source ${HOME}/.zshrc.user
EOF
