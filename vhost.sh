#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script como root ou usando sudo."
  exit 1
fi

# Solicitar o nome do domínio
read -p "Digite o nome do domínio/subdomínio (ex: livros.infabis.com.br): " DOMAIN

if [ -z "$DOMAIN" ]; then
  echo "O nome do domínio não pode ser vazio."
  exit 1
fi

# Solicitar o nome do arquivo de configuração do Nginx (sem extensão .conf)
read -p "Digite o nome do arquivo de configuração do Nginx (Enter = usar '$DOMAIN'): " CONFIG_NAME
if [ -z "$CONFIG_NAME" ]; then
    CONFIG_NAME="$DOMAIN"
fi

# Solicitar o nome da pasta do projeto dentro de /var/www/html/
read -p "Digite o nome da pasta do projeto em /var/www/html/ (Enter = usar '$DOMAIN'): " FOLDER_NAME
if [ -z "$FOLDER_NAME" ]; then
    FOLDER_NAME="$DOMAIN"
fi

# Detectar a versão do PHP-FPM instalada no sistema
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)

if [ -z "$PHP_VERSION" ]; then
    echo "⚠️ PHP não foi detectado no sistema. O script vai configurar o padrão PHP 8.1, mas certifique-se de instalar o php-fpm correspondente."
    PHP_VERSION="8.1"
fi

# Configuração dos caminhos locais
WEB_ROOT="/var/www/html/$FOLDER_NAME"
CONFIG_AVAILABLE="/etc/nginx/conf.d/$CONFIG_NAME.conf"

echo "--------------------------------------------"
echo "Iniciando a criação do Virtual Host (PHP) para: $DOMAIN"
echo "--------------------------------------------"

# 0. Perguntar o tipo de projeto
echo ""
echo "Que tipo de projeto é esse?"
echo "  1) PHP vanilla (sem framework)"
echo "  2) Framework PHP"
read -p "Escolha [1-2]: " PROJECT_KIND

FRAMEWORK=""
if [ "$PROJECT_KIND" = "2" ]; then
    echo ""
    echo "Qual framework?"
    echo "  1) Laravel [padrão]"
    echo "  2) CodeIgniter"
    echo "  3) Yii"
    read -p "Escolha [1-3] (Enter = Laravel): " FW_CHOICE

    case "$FW_CHOICE" in
        2) FRAMEWORK="codeigniter" ;;
        3) FRAMEWORK="yii" ;;
        *) FRAMEWORK="laravel" ;;
    esac
else
    FRAMEWORK="vanilla"
fi

echo "--------------------------------------------"
echo "Tipo de projeto selecionado: $FRAMEWORK"
echo "--------------------------------------------"

# Define o document root e o fallback de rotas de acordo com o tipo de projeto
if [ "$FRAMEWORK" = "laravel" ]; then
    DOC_ROOT="$WEB_ROOT/public"
    TRY_FILES='try_files $uri $uri/ /index.php?$query_string;'
else
    # Vanilla, CodeIgniter e Yii: sem ajuste automático por enquanto
    DOC_ROOT="$WEB_ROOT"
    TRY_FILES='try_files $uri $uri/ =404;'
fi

# 1. Criar o diretório raiz do site dentro de /var/www/html/
echo "Criando o diretório $WEB_ROOT..."
mkdir -p "$WEB_ROOT"

# Dono www-data:www-data com 775 (ambiente de testes: sem precisar ajustar permissão arquivo por arquivo)
echo "Ajustando dono/permissões para www-data:www-data (775)..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 775 "$WEB_ROOT"

# Inclui o usuário real do terminal no grupo www-data, para ele também ler/escrever sem sudo
if [ -n "$SUDO_USER" ] && ! id -nG "$SUDO_USER" | grep -qw "www-data"; then
    echo "Adicionando $SUDO_USER ao grupo www-data..."
    usermod -aG www-data "$SUDO_USER"
    echo "⚠️ $SUDO_USER precisa fazer logout/login (ou 'newgrp www-data') para o novo grupo valer na sessão atual."
fi

# 2. Criar uma página index.php de teste dinâmico (somente para projetos vanilla,
#    já que projetos com framework devem ter sua própria estrutura de entrada)
if [ "$FRAMEWORK" = "vanilla" ]; then
    echo "Criando página de teste index.php..."
    cat <<EOF > "$WEB_ROOT/index.php"
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Sucesso - $DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f4f4f4; }
        h1 { color: #009688; }
        .info { max-width: 600px; margin: 20px auto; text-align: left; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <h1>Parabéns! O Virtual Host PHP para <strong>$DOMAIN</strong> está online!</h1>
    <p>Diretório raiz: <code>$WEB_ROOT</code></p>

    <div class="info">
        <h3>Informações do Ambiente:</h3>
        <ul>
            <li><strong>Versão do PHP configurada:</strong> $PHP_VERSION</li>
            <li><strong>Data atual do servidor:</strong> <?php echo date('d/m/Y H:i:s'); ?></li>
        </ul>
    </div>
</body>
</html>
EOF
    # Ajusta o dono do arquivo index de teste
    chown www-data:www-data "$WEB_ROOT/index.php"
else
    echo "Projeto com framework ($FRAMEWORK) detectado: pulando criação de index.php de teste."
    if [ "$FRAMEWORK" = "laravel" ]; then
        echo "Certifique-se de que o projeto Laravel já esteja em $WEB_ROOT (com a pasta public/ dentro)."
    fi
fi

# 2b. Para Laravel, reforça o setgid nas pastas que o próprio framework precisa escrever
#     (storage/ e bootstrap/cache/), garantindo que arquivos criados por qualquer um
#     ali dentro herdem o grupo www-data
if [ "$FRAMEWORK" = "laravel" ]; then
    for DIR in "$WEB_ROOT/storage" "$WEB_ROOT/bootstrap/cache"; do
        if [ -d "$DIR" ]; then
            echo "Aplicando setgid em $DIR..."
            chmod -R 775 "$DIR"
            find "$DIR" -type d -exec chmod g+s {} \;
        else
            echo "⚠️ $DIR não encontrado ainda — rode este ajuste de novo depois que o projeto Laravel estiver na pasta."
        fi
    done
fi

# 3. Criar o arquivo de configuração do Nginx com suporte ao PHP
echo "Criando a configuração no Nginx..."
cat <<EOF > "$CONFIG_AVAILABLE"
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    root $DOC_ROOT;
    index index.php index.html index.htm;

    location / {
        $TRY_FILES
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/$DOMAIN.error.log;
    access_log /var/log/nginx/$DOMAIN.access.log;
}
EOF

# 4. Nada a habilitar: arquivos em /etc/nginx/conf.d/ já são lidos automaticamente
#    pelo Nginx (via "include conf.d/*.conf;" no nginx.conf principal)
echo "Configuração criada em $CONFIG_AVAILABLE (conf.d é incluído automaticamente pelo Nginx)."

# 5. Testar a configuração do Nginx e reiniciar o serviço
echo "Testando a configuração do Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Configuração válida! Reiniciando o Nginx..."
    systemctl restart nginx

    echo "--------------------------------------------"
    echo "Virtual Host do Nginx criado com sucesso!"
    echo "--------------------------------------------"

    # Pergunta interativa para o arquivo hosts
    read -p "Este domínio será usado APENAS LOCALMENTE nesta máquina? (s/n): " APENAS_LOCAL

    if [[ "$APENAS_LOCAL" =~ ^[Ss]$ ]]; then
        if grep -q -E "\b$DOMAIN\b" /etc/hosts; then
            echo "Aviso: O domínio $DOMAIN já está presente no seu arquivo /etc/hosts."
        else
            echo "Adicionando $DOMAIN ao arquivo /etc/hosts..."
            echo "127.0.0.1    $DOMAIN" >> /etc/hosts
            echo "127.0.0.1    www.$DOMAIN" >> /etc/hosts
            echo "Sucesso: Domínio mapeado localmente no /etc/hosts!"
        fi
    else
        echo "Pulando a configuração do /etc/hosts."
    fi
    echo "--------------------------------------------"
else
    echo "Erro na configuração do Nginx. Verifique o arquivo $CONFIG_AVAILABLE"
fi
