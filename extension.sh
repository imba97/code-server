#!/bin/bash

# 安装 vscode 插件

exts=(
  # 中文
  MS-CEINTL.vscode-language-pack-zh-hans
  # Volar
  Vue.volar
  # 颜色选择器
  anseki.vscode-color
  # js ts
  ms-vscode.vscode-typescript-next
)

for ext in ${exts[@]}
do
  code-server --install-extension $ext
done