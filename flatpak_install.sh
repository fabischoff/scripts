#!/bin/bash

# Script de instalação do Flatpak no Kubuntu
# Deve ser executado com permissões de administrador (sudo)

echo "--- Iniciando a instalação do Flatpak ---"

# 1. Atualizar lista de repositórios
echo "[1/3] Atualizando os repositórios..."
sudo apt update -y

# 2. Instalar Flatpak e o suporte para o KDE Discover
echo "[2/3] Instalando Flatpak e integração com o KDE Plasma..."
sudo apt install flatpak plasma-discover-backend-flatpak -y

# 3. Adicionar o repositório Flathub
echo "[3/3] Adicionando o repositório Flathub..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "----------------------------------------"
echo "Instalação concluída com sucesso!"
echo "Por favor, reinicie a sua sessão ou o computador para que"
echo "as alterações tenham efeito no Discover."
echo "----------------------------------------"
