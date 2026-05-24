#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Este script precisa ser executado como root."
  echo "Tente rodar novamente usando: sudo $0"
  exit 1
fi

# Senha fixa para o ambiente de testes
SENHA_TESTE="orRXUWR@a94k%$"

echo "--- Atualizando a lista de repositórios ---"
apt update

echo "--- Instalando o MySQL e o PostgreSQL ---"
apt install mysql-server postgresql postgresql-contrib -y

echo "--- Iniciando os serviços ---"
systemctl enable --now mysql
systemctl enable --now postgresql

echo "--- Aplicando configurações e criando usuários no MySQL ---"

# 1. Define a senha do root local
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${SENHA_TESTE}';"

# 2. Remove usuários anônimos
mysql -u root -p"${SENHA_TESTE}" -e "DELETE FROM mysql.user WHERE User='';"

# 3. Desabilita o login remoto para o root (boa prática até em testes)
mysql -u root -p"${SENHA_TESTE}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

# 4. Remove o banco de dados de teste original
mysql -u root -p"${SENHA_TESTE}" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"${SENHA_TESTE}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

# 5. Criação do usuário 'infabis' com permissões totais
echo "--- Criando usuário infabis ---"
mysql -u root -p"${SENHA_TESTE}" -e "CREATE USER 'infabis'@'%' IDENTIFIED WITH caching_sha2_password BY '${SENHA_TESTE}';"
mysql -u root -p"${SENHA_TESTE}" -e "GRANT ALL PRIVILEGES ON *.* TO 'infabis'@'%' WITH GRANT OPTION;"

# 6. Recarrega as tabelas de privilégios para aplicar tudo
mysql -u root -p"${SENHA_TESTE}" -e "FLUSH PRIVILEGES;"

echo "✅ Instalação, configuração de segurança e criação do usuário 'infabis' concluídas com sucesso!"
