# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:latest

LABEL MAINTAINER="mail@imba97.cn"

EXPOSE 8080

VOLUME [ "/home/coder" ]

ARG TARGETARCH

ENV HOST="code-server"

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
RUN chown -R coder:coder /tmp/nix

# 构建 Nix 环境
USER coder
RUN bash -c ". /home/coder/.nix-profile/etc/profile.d/nix.sh && cd /tmp/nix && nix --extra-experimental-features 'nix-command flakes' build .#default"

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

# 安装 VSCode 扩展 (从 Nix 生成的列表)
USER coder
RUN bash -c ". ~/.nix-profile/etc/profile.d/nix.sh && \
    while read ext; do code-server --install-extension \"$ext\" || true; done < ~/.nix-profile/etc/vscode-extensions.txt && \
    rm ~/.nix-profile/etc/vscode-extensions.txt"

# 清理临时文件
USER root
RUN rm -rf /tmp/nix /tmp/result* /tmp/nix.sh

# 添加 start 脚本
COPY ./scripts/start.sh /opt/
RUN chmod +x /opt/start.sh && \
    sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

USER coder
