#!/bin/bash

# 只执行一次

LOCK_FILE=after.lock

if [ ! -f ${LOCK_FILE} ]; then
    # source ${HOME}/.zshrc

    # 安装 nodejs
    nvm install 20.8.1
    nvm use 20.8.1

    # 设置镜像源
    npm config set registry https://registry.npmmirror.com/

    # 安装 npm 包
    npm i -g yarn pnpm

    echo "Locked" > ${LOCK_FILE}
fi
