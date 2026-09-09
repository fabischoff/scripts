#!/bin/bash

LINK_DESTINO="/usr/local/bin/atualizar"
ARQUIVO_ORIGEM="/home/fausto/Scripts/atualizar.sh"

echo "Verificando configurações iniciais..."

# O parâmetro -L verifica se o link simbólico já existe
if [ -L "$LINK_DESTINO" ]; then
    echo "Tudo certo! O atalho para a atualização já está configurado como 'atualizar'."
else
    echo "Atalho não encontrado. Criando o link simbólico agora..."
    sudo ln -s "$ARQUIVO_ORIGEM" "$LINK_DESTINO"
    echo "Link simbólico 'atualizar' criado com sucesso!"
fi
