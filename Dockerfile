# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:latest

LABEL MAINTAINER="mail@imba97.cn"

EXPOSE 8080

VOLUME [ "/home/coder" ]

ENV HOST="code-server"
ENV DEFAULT_WORKSPACE="/home/coder/workspace"
ENV NRM_REGISTRY="npm"

USER root

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

RUN apt update && \
    apt install -y --no-install-recommends \
      ca-certificates \
      curl \
      cron \
      zsh \
      git \
      sudo \
      gnupg

RUN install -d -m 0755 /etc/apt/keyrings

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

RUN apt update && \
    apt install -y --no-install-recommends nodejs

RUN corepack enable

RUN npm install -g npm-check-updates

RUN npm install -g eslint

RUN npm install -g nrm

RUN rm -rf /var/lib/apt/lists/*

RUN usermod -s /bin/zsh coder

RUN mkdir -p /opt/bootstrap-home

RUN mkdir -p /opt/code-config /opt/extensions /opt/code-server/extensions

RUN git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/bootstrap-home/.oh-my-zsh --depth=1

RUN git clone https://github.com/zsh-users/zsh-autosuggestions /opt/bootstrap-home/.oh-my-zsh/custom/plugins/zsh-autosuggestions --depth=1

RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting /opt/bootstrap-home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting --depth=1

RUN git clone https://github.com/spaceship-prompt/spaceship-prompt.git /opt/bootstrap-home/.oh-my-zsh/custom/themes/spaceship-prompt --depth=1

RUN ln -s /opt/bootstrap-home/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme /opt/bootstrap-home/.oh-my-zsh/custom/themes/spaceship.zsh-theme

COPY --chown=coder:coder ./scripts/zshrc /opt/bootstrap-home/.zshrc
COPY --chown=coder:coder ./User/settings.json /opt/code-config/
COPY ./scripts/install-extensions.sh /tmp/install-extensions.sh

RUN chmod +x /tmp/install-extensions.sh && \
    EXTENSIONS_DIR=/opt/extensions /tmp/install-extensions.sh && \
    for vsix in /opt/extensions/*.vsix; do \
      if [ -f "$vsix" ]; then \
        code-server --user-data-dir /tmp/code-server-data --extensions-dir /opt/code-server/extensions --install-extension "$vsix"; \
      fi; \
    done && \
    rm -rf /tmp/code-server-data /tmp/install-extensions.sh /opt/extensions

RUN chown -R coder:coder /opt/bootstrap-home /opt/code-config /opt/code-server/extensions

RUN mkdir -p /home/coder/.config/code-server && \
    chown -R coder:coder /home/coder/.config/code-server

COPY --chown=coder:coder ./scripts/start.sh /opt/
RUN chmod +x /opt/start.sh && \
    sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

USER coder
