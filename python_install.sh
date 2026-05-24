#!/bin/bash

# 1. Detecta a distribuição e instala as dependências necessárias para compilar o Python
if [ -f /etc/debian_version ]; then
    echo "Detectado sistema baseado em Ubuntu/Debian. Instalando dependências..."
    sudo apt update
    sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git
elif [ -f /etc/redhat-release ]; then
    echo "Detectado sistema baseado em RHEL/AlmaLinux. Instalando dependências..."
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y openssl-devel bzip2-devel libffi-devel readline-devel \
    sqlite-devel xz-devel zlib-devel gdbm-devel tk-devel git
fi

# 2. Instala o Pyenv
echo "Instalando o Pyenv..."
curl https://pyenv.run | bash

# 3. Configura as variáveis de ambiente no arquivo .bashrc do usuário
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

# Carrega as configurações na sessão atual do script
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# 4. Instala uma versão recente e estável do Python (ex: 3.12)
echo "Instalando o Python 3.12 através do Pyenv (isso pode demorar alguns minutos)..."
pyenv install 3.12

# Define a versão 3.12 como a global do seu usuário
pyenv global 3.12

echo "--- Instalação do Pyenv e Python concluída! ---"
echo -n "Versão do Python: " && python3 -V
echo -n "Versão do Pip:    " && pip3 -V
