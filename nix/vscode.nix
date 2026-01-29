# VSCode 扩展列表
{ pkgs }:
pkgs.writeText "vscode-extensions.txt" ''
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
''
