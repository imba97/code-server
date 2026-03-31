# 开发工具包定义
{ pkgs }:
with pkgs;
[
  nodejs_22
  corepack
  yarn
  pnpm
  nodePackages.nrm
  nodePackages.npm-check-updates
  nodePackages.eslint
  python3
  gcc
  gnumake
  pkg-config
  jq
  ripgrep
  fd
  fzf
  git-lfs
  gh
  git
  vim
]
