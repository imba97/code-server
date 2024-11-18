#!/bin/bash

# 安装 vscode 插件

exts=(
  MS-CEINTL.vscode-language-pack-zh-hans
  Vue.volar
  anseki.vscode-color
  ms-vscode.vscode-typescript-next
  eamodio.gitlens
  YoavBls.pretty-ts-errors
  foxundermoon.shell-format
  dbaeumer.vscode-eslint
  usernamehw.errorlens
  antfu.unocss
  antfu.iconify
  antfu.icons-carbon
  antfu.theme-vitesse
)

for ext in ${exts[@]}
do
  code-server --install-extension $ext
done
