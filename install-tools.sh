#!/bin/bash

set -eux

TARGET_PATH=/usr/local/bin
TEMP_DIR=$(mktemp -d)

# https://github.com/ehang-io/nps/releases/latest
NPS_VERSION="v0.26.10"
# https://github.com/nvm-sh/nvm/releases/latest
NVM_VERSION="v0.39.3"

# nps 客户端
mkdir ${TEMP_DIR}/npc
curl -#fSLo ${TEMP_DIR}/npc/linux_${TARGETARCH}_client.tar.gz https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/linux_${TARGETARCH}_client.tar.gz
tar -zxf ${TEMP_DIR}/npc/linux_${TARGETARCH}_client.tar.gz -C ${TEMP_DIR}/npc
${TEMP_DIR}/npc/npc install

# 安装 docker 客户端
if [ ${TARGETARCH} = "amd64" ]; then
  DOCKER_ARCH=x86_64
elif [ ${TARGETARCH} = "arm64" ]; then
  DOCKER_ARCH=aarch64
fi

# 授权，清理
chmod +x ${TARGET_PATH}/*
rm -rf ${TEMP_DIR}
