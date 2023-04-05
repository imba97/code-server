#!/bin/bash

source ${HOME}/.zshrc

# 安装 nodejs
nvm install 16.20.0
nvm use 16.20.0

# 安装 npm 包
npm i -g yarn pnpm @vue/cli
