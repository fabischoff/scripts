#!/usr/bin/env bash
# ==============================================================================
# Script de Configuração de VirtualHost Nginx + Instalação Laravel (Kubuntu)
# ==============================================================================

set -euo pipefail

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Checagem de privilégios root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERRO] Execute este script com sudo: sudo ./setup-laravel-nginx.sh${NC}" >&2
   exit 1
fi

# Captura o usuário não-root original
REAL_USER="${SUDO_USER:-$USER}"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}    Assistente Nginx + Laravel no Kubuntu            ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Obter nome da aplicação
read -rp "Informe o nome da aplicação (ex: meu-projeto): " APP_NAME
if [[ -z "$APP_NAME" ]]; then
    echo -e "${RED}[ERRO] O nome da aplicação não pode ser vazio.${NC}"
    exit 1
fi

# 2. Obter diretório base onde a aplicação ficará
read -rp "Diretório base da aplicação [Padrão: /var/www/html]: " BASE_DIR
BASE_DIR="${BASE_DIR:-/var/www/html}"
BASE_DIR="${BASE_DIR%/}"

PROJECT_PATH="$BASE_DIR/$APP_NAME"

# 3. Obter nome do domínio
DEFAULT_DOMAIN="${APP_NAME}.test"
read -rp "Informe o domínio local [Padrão: $DEFAULT_DOMAIN]: " DOMAIN
DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"

# 4. Verificar se o projeto existe ou instalar com Composer
if [[ -d "$PROJECT_PATH" ]] && [[ -f "$PROJECT_PATH/artisan" ]]; then
    echo -e "${YELLOW}[INFO] Projeto Laravel existente detectado em: $PROJECT_PATH${NC}"
else
    echo -e "\n${BLUE}Projeto não encontrado em '$PROJECT_PATH'. Iniciando instalação via Composer...${NC}"

    # Pergunta da versão
    read -rp "Qual versão do Laravel deseja instalar? (ex: 11, ^11.0) [Em branco = versão atual]: " LARAVEL_VERSION

    if [[ -z "$LARAVEL_VERSION" ]]; then
        PACKAGE="laravel/laravel"
    else
        if [[ "$LARAVEL_VERSION" =~ ^[0-9]+$ ]]; then
            PACKAGE="laravel/laravel:^${LARAVEL_VERSION}.0"
        else
            PACKAGE="laravel/laravel:${LARAVEL_VERSION}"
        fi
    fi

    # Garante que o diretório base existe e tem permissão para o usuário real
    mkdir -p "$BASE_DIR"
    chown "$REAL_USER:$REAL_USER" "$BASE_DIR"

    # Verifica se o Composer está presente
    if ! command -v composer &> /dev/null; then
        echo -e "${RED}[ERRO] Composer não encontrado! Instale-o antes de prosseguir: sudo apt install composer${NC}"
        exit 1
    fi

    echo -e "${GREEN}Instalando $PACKAGE em $PROJECT_PATH...${NC}"
    sudo -u "$REAL_USER" composer create-project "$PACKAGE" "$PROJECT_PATH"
    echo -e "${GREEN}[OK] Laravel instalado com sucesso!${NC}\n"
fi

# 5. Detectar versão do PHP-FPM
DETECTED_PHP=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.3")
read -rp "Versão do PHP-FPM a ser usada [Padrão: ${DETECTED_PHP}]: " PHP_VERSION
PHP_VERSION="${PHP_VERSION:-${DETECTED_PHP}}"

PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"
if [[ ! -S "$PHP_SOCKET" ]]; then
    echo -e "${YELLOW}[AVISO] O socket '$PHP_SOCKET' não foi encontrado.${NC}"
    echo -e "Certifique-se de que o pacote 'php${PHP_VERSION}-fpm' está instalado e em execução."
fi

NGINX_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

# 6. Criar arquivo de configuração do Nginx
echo -e "${BLUE}Gerando configuração do Nginx em: $NGINX_AVAILABLE...${NC}"

cat > "$NGINX_AVAILABLE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $PROJECT_PATH/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# 7. Criar link simbólico para ativar o site
ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED"
echo -e "${GREEN}[OK] Link simbólico criado em sites-enabled.${NC}"

# 8. Atualizar /etc/hosts
if ! grep -q -E "\s+$DOMAIN(\s+|$)" /etc/hosts; then
    echo "127.0.0.1   $DOMAIN" >> /etc/hosts
    echo -e "${GREEN}[OK] Entrada adicionada em /etc/hosts.${NC}"
else
    echo -e "${YELLOW}[INFO] O domínio '$DOMAIN' já existe em /etc/hosts.${NC}"
fi

# 9. Permissões de storage e cache
if [[ -d "$PROJECT_PATH/storage" ]] && [[ -d "$PROJECT_PATH/bootstrap/cache" ]]; then
    echo -e "${BLUE}Ajustando permissões para 'storage' e 'bootstrap/cache'...${NC}"
    chown -R "$REAL_USER:www-data" "$PROJECT_PATH/storage" "$PROJECT_PATH/bootstrap/cache"
    chmod -R ug+rwx "$PROJECT_PATH/storage" "$PROJECT_PATH/bootstrap/cache"
    echo -e "${GREEN}[OK] Permissões de storage e cache configuradas.${NC}"
fi

# 10. Permissões específicas para o banco SQLite
if [[ -d "$PROJECT_PATH/database" ]]; then
    echo -e "${BLUE}Configurando permissões na pasta 'database' (SQLite)...${NC}"
    chown -R "$REAL_USER:www-data" "$PROJECT_PATH/database"
    chmod -R 775 "$PROJECT_PATH/database"

    find "$PROJECT_PATH/database" -type f -name "*.sqlite*" -exec chmod 664 {} +
    echo -e "${GREEN}[OK] Permissões de escrita do SQLite ajustadas.${NC}"
fi

# 11. Testar configuração e recarregar o Nginx
echo -e "\n${BLUE}Testando configuração do Nginx...${NC}"
if nginx -t; then
    systemctl reload nginx
    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN} Configuração finalizada com sucesso!               ${NC}"
    echo -e "${GREEN} Projeto: $PROJECT_PATH                             ${NC}"
    echo -e "${GREEN} Acesse pelo navegador: http://$DOMAIN             ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
else
    echo -e "\n${RED}[ERRO] Falha na sintaxe do Nginx. Nenhuma alteração foi recarregada.${NC}"
    exit 1
fi
