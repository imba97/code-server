# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:latest

LABEL MAINTAINER="mail@imba97.cn"

EXPOSE 8080 22

VOLUME [ "/home/coder" ]

ARG TARGETARCH

ENV HOST="code-server"

USER root

# 初始化配置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone
RUN usermod -s /bin/zsh coder

# 安装 cron 和 xz (Nix 需要 xz 解压)
RUN apt update
RUN apt install -y cron xz-utils ca-certificates curl

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
# 备份 nix.sh
RUN cp /home/coder/.nix-profile/etc/profile.d/nix.sh /tmp/nix.sh
RUN rm -rf /home/coder/.nix-profile/*
RUN cp -r /tmp/nix/result/* /home/coder/.nix-profile/
# 恢复 nix.sh
RUN mkdir -p /home/coder/.nix-profile/etc/profile.d
RUN cp /tmp/nix.sh /home/coder/.nix-profile/etc/profile.d/nix.sh

# 生成 .zshrc (直接使用 .nix-profile/share 路径，不使用 nix store 路径)
RUN mkdir -p /home/coder/.oh-my-zsh/custom/themes && \
    /home/coder/.nix-profile/bin/git clone https://github.com/denysdovhan/spaceship-prompt.git /home/coder/.oh-my-zsh/custom/themes/spaceship-prompt --depth=1 && \
    ln -s /home/coder/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme /home/coder/.oh-my-zsh/custom/themes/spaceship.zsh-theme && \
    echo "ZSH=/home/coder/.nix-profile/share/oh-my-zsh" > /home/coder/.zshrc && \
    echo "ZSH_CUSTOM=/home/coder/.oh-my-zsh/custom" >> /home/coder/.zshrc && \
    echo "ZSH_THEME=\"spaceship\"" >> /home/coder/.zshrc && \
    echo "plugins=(git)" >> /home/coder/.zshrc && \
    echo "ZSH_CACHE_DIR=\$HOME/.cache/oh-my-zsh" >> /home/coder/.zshrc && \
    echo "if [[ ! -d \$ZSH_CACHE_DIR ]]; then" >> /home/coder/.zshrc && \
    echo "  mkdir -p \$ZSH_CACHE_DIR" >> /home/coder/.zshrc && \
    echo "fi" >> /home/coder/.zshrc && \
    echo "source \$ZSH/oh-my-zsh.sh" >> /home/coder/.zshrc && \
    echo "" >> /home/coder/.zshrc && \
    echo "export DEFAULT_WORKSPACE=\"\$HOME/workspace\"" >> /home/coder/.zshrc && \
    echo "if [[ ! -d \$DEFAULT_WORKSPACE ]]; then" >> /home/coder/.zshrc && \
    echo "  mkdir -p \$DEFAULT_WORKSPACE" >> /home/coder/.zshrc && \
    echo "fi" >> /home/coder/.zshrc && \
    echo "" >> /home/coder/.zshrc && \
    echo "source /home/coder/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /home/coder/.zshrc && \
    echo "source /home/coder/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /home/coder/.zshrc && \
    echo "" >> /home/coder/.zshrc && \
    echo "alias ll=\"ls -l --color=auto\"" >> /home/coder/.zshrc && \
    echo "alias ls=\"ls --color=auto\"" >> /home/coder/.zshrc && \
    echo "alias cp=\"cp -i\"" >> /home/coder/.zshrc && \
    echo "alias mv=\"mv -i\"" >> /home/coder/.zshrc && \
    echo "alias rm=\"trash\"" >> /home/coder/.zshrc && \
    echo "export HIST_STAMPS=\"yyyy-mm-dd\"" >> /home/coder/.zshrc && \
    echo "export VISUAL=vim" >> /home/coder/.zshrc && \
    echo "export EDITOR=\"\$VISUAL\"" >> /home/coder/.zshrc && \
    echo "[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && source ~/.nix-profile/etc/profile.d/nix.sh || true" >> /home/coder/.zshrc && \
    echo "[ -f \$HOME/.zshrc.user ] && source \$HOME/.zshrc.user" >> /home/coder/.zshrc

RUN mkdir -p /opt/code-config
COPY ./User/settings.json /opt/code-config/
RUN chown -R coder:coder /home/coder/.nix-profile /home/coder/.zshrc /opt/code-config
USER coder

# 安装 VSCode 扩展 (从 Nix 生成的列表)
RUN bash -c ". ~/.nix-profile/etc/profile.d/nix.sh && while read ext; do code-server --install-extension \"$ext\" || true; done < ~/.nix-profile/etc/vscode-extensions.txt"
USER root
RUN rm /home/coder/.nix-profile/etc/vscode-extensions.txt
USER coder

# 清理临时文件
USER root
RUN rm -rf /tmp/nix /tmp/result*

# 添加 start 脚本
COPY ./scripts/start.sh /opt/
RUN chmod +x /opt/start.sh
RUN sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

USER coder
