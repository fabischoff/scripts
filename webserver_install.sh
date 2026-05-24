#!/bin/bash

# Aborta o script em caso de erro
set -e

echo "=== Atualizando as listas de pacotes ==="
sudo apt update -y

echo "=== Instalando o Nginx e PHP-FPM ==="
sudo apt install -y nginx php-fpm

echo "=== Configurando o Vim como editor padrão no ambiente ==="
if ! grep -q "export EDITOR=" ~/.bashrc; then
    echo 'export EDITOR="vim"' >> ~/.bashrc
    echo 'export VISUAL="vim"' >> ~/.bashrc
    source ~/.bashrc
fi

echo "=== Iniciando e habilitando os serviços ==="
sudo systemctl start nginx
sudo systemctl enable nginx

# Identifica a versão do PHP instalada para iniciar o serviço correto do FPM
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sudo systemctl start php$PHP_VERSION-fpm
sudo systemctl enable php$PHP_VERSION-fpm

echo "=== Verificando o status dos serviços ==="
systemctl status nginx --no-pager -n 2
systemctl status php$PHP_VERSION-fpm --no-pager -n 2

sudo chmod -R 775 /var/www/html/
sudo chown -R fausto:www-data /var/www/htm

echo "========================================="
echo " Instalação concluída com sucesso! "
echo " Versão do PHP instalada: $PHP_VERSION "
echo "========================================="
