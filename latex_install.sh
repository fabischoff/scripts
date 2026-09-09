#!/bin/bash

# Atualiza a lista de pacotes
echo "Atualizando repositórios..."
sudo apt update

# Instala o LaTeX completo e ferramentas de compilação
echo "Instalando TeX Live Full e Latexmk (isso pode demorar um pouco)..."
sudo apt install -y texlive-full latexmk

# Instala o xdotool (ajuda na sincronização do PDF com o editor)
echo "Instalando utilitários adicionais..."
sudo apt install -y xdotool

echo "Instalação do LaTeX concluída com sucesso!"
