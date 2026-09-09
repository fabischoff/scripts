#!/bin/bash

# 1. Atualiza os repositórios do sistema
echo "Atualizando pacotes do sistema..."
sudo apt-get update && sudo apt-get install -y curl unzip nodejs npm

# 2. Instala o gerenciador 'n' globalmente
echo "Instalando o maestro 'n' (Gerenciador de Versões)..."
sudo npm install n -g

# 3. Instala a versão LTS mais recente do Node.js
echo "Baixando e ativando a versão LTS mais recente..."
sudo n lts

# 4. Remove a versão nativa do Ubuntu para evitar conflitos (O "Fura-Fila")
echo "Limpando a instalação do sistema operacional..."
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y

# 5. Limpa a memória de comandos do terminal atual
hash -r

# 6. Verifica as versões instaladas
echo "--- Instalação concluída com sucesso! ---"
echo -n "Versão do Node: " && node -v
echo -n "Versão do NPM:  " && npm -v
