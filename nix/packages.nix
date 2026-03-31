# 开发工具包定义
{ pkgs }:
with pkgs;
[
  nodejs
  yarn
  pnpm
  nodePackages.nrm
  git
  vim
]
