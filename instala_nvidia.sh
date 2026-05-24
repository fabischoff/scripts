#!/bin/bash

# Verifica se o script está sendo executado como root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script com privilégios de administrador (sudo ./instala_nvidia.sh)"
  exit 1
fi

echo "Iniciando a instalação dos drivers NVIDIA..."

# Passo 1: Importar a chave GPG do repositório ELRepo
echo "[1/3] Importando chave GPG do ELRepo..."
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

# Passo 2: Instalar o repositório ELRepo (versão 10)
echo "[2/3] Instalando o repositório ELRepo para a versão 10..."
dnf install -y https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm

# Passo 3: Instalar o driver da NVIDIA e o módulo do kernel
echo "[3/3] Instalando os pacotes kmod-nvidia e nvidia-x11-drv..."
dnf install -y kmod-nvidia nvidia-x11-drv

echo "========================================================="
echo "Instalação base concluída com sucesso!"
echo "ATENÇÃO: É necessário reiniciar o sistema para carregar o novo módulo do kernel."
echo "Após o reinício, execute 'nvidia-smi' no terminal para validar."
echo "========================================================="
