#!/bin/bash

# 安装 vscode 插件

exts=(
  # 中文，各种方式配置语言包均不生效
  # MS-CEINTL.vscode-language-pack-zh-hans
  # Volar
  Vue.volar
  # 颜色选择器
  anseki.vscode-color
  # typescript
  ms-vscode.vscode-typescript-next
  # Prettier
  esbenp.prettier-vscode
  # GitLens
  eamodio.gitlens
)

for ext in ${exts[@]}
do
  code-server --install-extension $ext
done