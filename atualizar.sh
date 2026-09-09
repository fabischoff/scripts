#!/bin/bash

echo "=== Atualizando Sistema Base (APT) ==="
sudo apt update && sudo apt upgrade -y

echo "=== Atualizando Aplicativos Snap ==="
sudo snap refresh

echo "=== Atualizando Aplicativos Flatpak ==="
flatpak update -y

echo "=== Atualizando Firmwares ==="
fwupdmgr refresh && fwupdmgr update

echo "=== Atualização Completa! ==="
