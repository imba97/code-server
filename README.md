# imba97-code-server

个人 `code-server` 配置方案。

参考项目：[monlor/docker-code-server](https://github.com/monlor/docker-code-server)

## 功能

- 默认使用 `zsh`，并集成 `oh-my-zsh`
- 内置前端开发工具，包括 `node`、`npm`、`pnpm`、`yarn`、`nrm`、`eslint`
- 内置基础命令行工具，包括 `git`
- 容器启动时会自动补齐 `~/.zshrc` 和 `oh-my-zsh` 配置，兼容已有的 `/home/coder` 持久卷
- 首次启动时生成 `~/.frontend-env.log`，记录当前工具版本和 npm registry 信息
- 镜像构建阶段会预下载 VS Code 扩展，首次启动时直接安装本地 VSIX

## 环境变量

可在 `docker-compose.yaml` 中覆盖以下变量：

- `NRM_REGISTRY`：默认值为 `npm`
- `DEFAULT_WORKSPACE`：默认值为 `/home/coder/workspace`

## 扩展管理

- [scripts/install-extensions.sh](scripts/install-extensions.sh) 会在镜像构建阶段直接从 VS Code Marketplace 下载扩展
- 下载完成后会在构建阶段安装到镜像内的全局扩展目录
- 容器启动时只会将用户扩展目录指向镜像内的全局扩展目录，不再逐个安装扩展

## 相关脚本

- [Dockerfile](Dockerfile)：安装前端开发工具和基础环境
- [scripts/install-extensions.sh](scripts/install-extensions.sh)：镜像构建阶段下载扩展 VSIX
- [scripts/zshrc](scripts/zshrc)：默认 shell 配置
- [scripts/start.sh](scripts/start.sh)：启动时执行环境初始化和本地扩展安装
