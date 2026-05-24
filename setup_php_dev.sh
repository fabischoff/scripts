#!/bin/bash


# Solicita que você digite o caminho do arquivo
read -p "Digite o caminho completo do php.ini que deseja alterar (ex: /etc/php.ini): " PHP_INI

# Verifica se o arquivo informado existe
if [ ! -f "$PHP_INI" ]; then
    echo "❌ Erro: O arquivo '$PHP_INI' não foi encontrado. Verifique o caminho e tente novamente."
    exit 1
fi

echo "✅ Arquivo validado. Utilizando: $PHP_INI"
echo "--- Iniciando Tunagem do PHP.ini ---"


# Função para garantir que a configuração exista e esteja correta
# Ela lida com linhas comentadas ou já existentes
configurar_diretiva() {
    local chave=$1
    local valor=$2

    # Se a linha existir (comentada ou não), substitui.
    # Se não existir, adiciona ao final do arquivo.
    if grep -q "^[; ]*$chave =" "$PHP_INI"; then
        sudo sed -i "s/^[; ]*$chave =.*/$chave = $valor/" "$PHP_INI"
    else
        echo "$chave = $valor" | sudo tee -a "$PHP_INI"
    fi
    echo "✔️ $chave definido para $valor"
}

echo "--- Iniciando Tunagem do PHP.ini ---"

# Suas solicitações específicas
configurar_diretiva "display_errors" "On"
configurar_diretiva "error_reporting" "E_ALL"
configurar_diretiva "html_errors" "On"
configurar_diretiva "short_open_tag" "On"

# Recomendações extras para acompanhar o seu setup
configurar_diretiva "display_startup_errors" "On"
configurar_diretiva "log_errors" "On"

echo "--- Reiniciando o Servidor ---"
# Extrai o ID do sistema operacional removendo aspas, se houver
OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')

if [ "$OS_ID" == "almalinux" ]; then

    echo "✅ AlmaLinux detectado."
    systemctl restart httpd

elif [ "$OS_ID" == "ubuntu" ]; then

    if [ -z "$PHP_INI" ]; then
        echo "❌ Arquivo php.ini não encontrado no Ubuntu."
        exit 1
    fi
    echo "✅ Ubuntu detectado."
    systemctl restart nginx

else
    echo "⚠️ Sistema Operacional não identificado ou não suportado ($OS_ID)."
    exit 1
fi



echo "Configuração concluída! Seu PHP agora é um dedo-duro profissional."






