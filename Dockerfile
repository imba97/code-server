# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:4.11.0

LABEL MAINTAINER="me@monlor.com"

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
  apt update && apt install -y cron vim trash-cli openssh-server nodejs && \
  # npm 工具
  npm install --global pnpm && \
  # 配置 openssh，这里需要固化 ssh server 的密钥
  mkdir -p /var/run/sshd && \
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config

# 安装oh-my-zsh
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
  git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh/plugins/zsh-autosuggestions && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh/plugins/zsh-syntax-highlighting

# 安装依赖工具
COPY ./install-tools.sh /opt/scripts/
RUN bash /opt/scripts/install-tools.sh 

# 添加start脚本
COPY ./start.sh /opt/
RUN chmod +x /opt/start.sh && sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

# 添加vscode插件
COPY ./extensions /opt/extensions

USER coder