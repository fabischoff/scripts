#!/bin/bash

# Atualiza os repositórios do sistema
echo "Atualizando pacotes do sistema..."
sudo apt update && sudo apt install -y curl unzip

# Baixa e instala o Fast Node Manager (fnm)
echo "Instalando o fnm (Fast Node Manager)..."
curl -fsSL https://fnm.vercel.app/install | bash

# Ativa o fnm na sessão atual do shell (assumindo o Bash padrão do Kubuntu)
export PATH="$HOME/.local/share/fnm:$PATH"
eval "`fnm env`"

# Instala a versão LTS mais recente do Node.js e do npm
echo "Instalando a versão LTS mais recente do Node.js..."
fnm install --lts

# Define a versão LTS como padrão global
fnm use lts-latest

# Verifica as versões instaladas
echo "--- Instalação concluída com sucesso! ---"
echo -n "Versão do Node: " && node -v
echo -n "Versão do NPM:  " && npm -v
