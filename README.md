# imba97-code-server

个人 `code-server` 配置方案

方案参考：[monlor/docker-code-server](https://github.com/monlor/docker-code-server)

## 更新扩展

- 在 [scripts/update-extensions.ts](scripts/update-extensions.ts) 里的 `MANAGED_EXTENSIONS` 维护要跟踪的扩展 ID。
- 运行 `pnpm run update-extensions` 后，脚本会从 VS Code Marketplace 下载每个扩展的最新 VSIX 到 [extensions](extensions) 目录。
- 同一扩展只保留一个最新版本文件，容器首次启动时会自动安装这些本地 VSIX。
