#!/bin/bash

source ${HOME}/.zshrc

# 只执行一次

LOCK_FILE=after.lock

if [ -f ${LOCK_FILE} ]; then
    # Lock file already exists, exit the script
    echo "An instance of this script is already running"
    exit 1
fi

# 安装 nodejs
nvm install 16.14.0
nvm use 16.14.0

# 设置镜像源
npm config set registry https://registry.npm.taobao.org

# 安装 npm 包
npm i -g yarn pnpm @vue/cli

echo "Locked" > ${LOCK_FILE}
