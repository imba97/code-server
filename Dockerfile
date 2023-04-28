# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:latest

LABEL MAINTAINER="mail@imba97.cn"

EXPOSE 8080 22

VOLUME [ "/home/coder" ]

ARG TARGETARCH

ENV HOST="code-server"

USER root

# 初始化配置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
  # 修改用户默认 shell
  usermod -s /bin/zsh coder

# 安装常用工具
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
  apt update && apt install -y cron vim trash-cli openssh-server build-essential && \
  # 配置 openssh，这里需要固化 ssh server 的密钥
  mkdir -p /var/run/sshd && \
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config

# 安装oh-my-zsh
COPY ./scripts/zsh-installer.sh /opt/scripts/
RUN bash /opt/scripts/zsh-installer.sh

# 安装依赖工具
COPY ./scripts/install-tools.sh /opt/scripts/
RUN bash /opt/scripts/install-tools.sh

# 添加 start 脚本
COPY ./scripts/start.sh /opt/
RUN chmod +x /opt/start.sh && sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

# start 后脚本
COPY ./scripts/after.sh /opt/
RUN chmod +x /opt/after.sh && sed -i '/^exec/i nohup /opt/after.sh' /usr/bin/entrypoint.sh

# vscode 配置存放目录
RUN mkdir /opt/code-config

# vscode 配置
COPY ./User/settings.json /opt/code-config/

USER coder

# 安装 vscode 插件
COPY ./scripts/extension.sh /opt/scripts/
RUN bash /opt/scripts/extension.sh
