# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:latest

LABEL MAINTAINER="mail@imba97.cn"

EXPOSE 8080

VOLUME [ "/home/coder" ]

ARG TARGETARCH

ENV HOST="code-server"
# 默认工作目录
ENV DEFAULT_WORKSPACE="/home/coder/workspace"

USER root

# 初始化配置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    usermod -s /bin/zsh coder && \
    apt update && \
    apt install -y cron xz-utils ca-certificates curl

# 切换到 coder 用户安装 Nix
USER coder
RUN bash -c "curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon --no-modify-profile"

# 复制 nix 配置目录
USER root
COPY ./nix /tmp/nix
RUN mkdir -p /home/coder/.config/nix && \
    cp /tmp/nix/nix.conf /home/coder/.config/nix/nix.conf && \
    chown -R coder:coder /tmp/nix /home/coder/.config/nix

# 构建 Nix 环境 (使用 BuildKit 缓存加速)
USER coder
RUN --mount=type=cache,target=/home/coder/.cache/nix,uid=1000,gid=1000 \
    bash -c ". /home/coder/.nix-profile/etc/profile.d/nix.sh && cd /tmp/nix && nix --extra-experimental-features 'nix-command flakes' build .#default"

# 安装构建结果
USER root
RUN cp /home/coder/.nix-profile/etc/profile.d/nix.sh /tmp/nix.sh && \
    rm -rf /home/coder/.nix-profile/* && \
    cp -r /tmp/nix/result/* /home/coder/.nix-profile/ && \
    mkdir -p /home/coder/.nix-profile/etc/profile.d && \
    cp /tmp/nix.sh /home/coder/.nix-profile/etc/profile.d/nix.sh

# 安装 spaceship 主题
RUN mkdir -p /home/coder/.oh-my-zsh/custom/themes && \
    /home/coder/.nix-profile/bin/git clone https://github.com/denysdovhan/spaceship-prompt.git /home/coder/.oh-my-zsh/custom/themes/spaceship-prompt --depth=1 && \
    ln -s /home/coder/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme /home/coder/.oh-my-zsh/custom/themes/spaceship.zsh-theme

# 复制由 Nix 生成的 .zshrc、VSCode 配置并设置权限
RUN cp /home/coder/.nix-profile/etc/.zshrc /home/coder/.zshrc && \
    mkdir -p /opt/code-config
COPY ./User/settings.json /opt/code-config/
RUN chown -R coder:coder /home/coder/.nix-profile /home/coder/.zshrc /opt/code-config

# 复制 VSCode 扩展文件（启动时安装）
# 将 VSIX 文件复制到 /opt/extensions，由 start.sh 在首次启动时安装
COPY ./extensions /opt/extensions
RUN mkdir -p /opt/extensions && \
    chown -R coder:coder /opt/extensions

# 清理临时文件
USER root
RUN rm -rf /tmp/nix /tmp/result* /tmp/nix.sh && \
    mkdir -p /home/coder/.config/code-server && \
    chown -R coder:coder /home/coder/.config

# 添加 start 脚本
COPY ./scripts/start.sh /opt/
RUN chmod +x /opt/start.sh && \
    sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

USER coder
