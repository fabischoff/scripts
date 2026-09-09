#!/usr/bin/env bash

# Interrompe a execução caso algum comando falhe
set -e

echo "1. Instalando extensões necessárias do PHP..."
sudo apt update
sudo apt install php-curl php-zip php-sqlite3 -y

echo "2. Baixando o instalador do Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

echo "3. Instalando o Composer globalmente em /usr/local/bin..."
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

echo "4. Removendo arquivo instalador temporário..."
php -r "unlink('composer-setup.php');"

echo "5. Baixando e configurando as chaves públicas oficiais do Composer..."
# Garante a existência do diretório de configuração do usuário atual
mkdir -p "$HOME/.config/composer"

# Baixa as chaves oficiais para verificação de tags e branches de desenvolvimento
curl -sS https://composer.github.io/releases.pub -o "$HOME/.config/composer/keys.tags.pub"
curl -sS https://composer.github.io/releases.dev.pub -o "$HOME/.config/composer/keys.dev.pub"

echo "6. Verificação de versão:"
composer --version

echo "7. Executando diagnóstico do ambiente:"
composer diagnose
