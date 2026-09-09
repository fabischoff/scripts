#!/bin/bash

# Script de instalação automatizada do VirtualBox para Kubuntu 26.04

echo "1. Atualizando os repositórios do sistema..."
sudo apt update

echo "2. Instalando o VirtualBox e o pacote de extensões..."
sudo apt install virtualbox virtualbox-ext-pack -y

echo "3. Adicionando o usuário atual ao grupo vboxusers..."
sudo usermod -aG vboxusers $USER

echo "Procedimento concluído com sucesso!"

read -p "Deseja reiniciar o computador agora para aplicar as configurações? (s/n): " opcao
if [[ "$opcao" == "s" || "$opcao" == "S" ]]; then
    echo "Reiniciando o sistema..."
    sudo reboot
else
    echo "Instalação finalizada. Lembre-se de reiniciar o sistema manualmente mais tarde."
fi
