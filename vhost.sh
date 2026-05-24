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

# Detectar a versão do PHP-FPM instalada no sistema
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)

if [ -z "$PHP_VERSION" ]; then
    echo "⚠️ PHP não foi detectado no sistema. O script vai configurar o padrão PHP 8.1, mas certifique-se de instalar o php-fpm correspondente."
    PHP_VERSION="8.1"
fi

# Configuração dos caminhos locais
WEB_ROOT="/var/www/html/$DOMAIN"
CONFIG_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
CONFIG_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

echo "--------------------------------------------"
echo "Iniciando a criação do Virtual Host (PHP) para: $DOMAIN"
echo "--------------------------------------------"

# 1. Criar o diretório raiz do site dentro de /var/www/html/
echo "Criando o diretório $WEB_ROOT..."
mkdir -p "$WEB_ROOT"

# Define o usuário real do terminal como dono e o Nginx (www-data) como o grupo da pasta do site
chown -R $SUDO_USER:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# 2. Criar uma página index.php de teste dinâmico
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

# Ajusta a permissão do arquivo index para o seu usuário e grupo do nginx
chown $SUDO_USER:www-data "$WEB_ROOT/index.php"

# 3. Criar o arquivo de configuração do Nginx com suporte ao PHP
echo "Criando a configuração no Nginx..."
cat <<EOF > "$CONFIG_AVAILABLE"
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    root $WEB_ROOT;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
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

# 4. Habilitar o site criando o link simbólico
if [ ! -f "$CONFIG_ENABLED" ]; then
    echo "Habilitando o site..."
    ln -s "$CONFIG_AVAILABLE" "$CONFIG_ENABLED"
fi

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
