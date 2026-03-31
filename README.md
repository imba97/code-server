# imba97-code-server

个人 `code-server` 配置方案

方案参考：[monlor/docker-code-server](https://github.com/monlor/docker-code-server)

## 更新扩展

- 在 [scripts/install-extensions.ts](scripts/install-extensions.ts) 里的 `MANAGED_EXTENSIONS` 维护要跟踪的扩展 ID。
- 运行 `pnpm run install-extensions` 后，脚本会把最新 VSIX 下载到 `.cache/extensions`；也可以通过 `EXTENSIONS_DIR` 覆盖输出目录。
- Docker 镜像在构建阶段会自动运行这个脚本，把下载好的 VSIX 复制进镜像里的 `/opt/extensions`。
- 容器首次启动时会安装这些镜像内置的本地 VSIX，因此仓库里不再需要提交扩展二进制文件。
