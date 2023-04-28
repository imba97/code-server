HOME=/home/coder

if [ ! -f ${HOME}/.oh-my-zsh/oh-my-zsh.sh ]; then
    echo "安装 oh-my-zsh ..."
    rm -rf ${HOME}/.oh-my-zsh
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 安装 zsh 主题
if [ ! -f ${HOME}/.oh-my-zsh/custom/themes/jovial.zsh-theme ]; then
    curl -sSL "https://github.com/zthxxx/jovial/raw/master/jovial.zsh-theme" -o ${HOME}/.oh-my-zsh/custom/themes/jovial.zsh-theme
fi