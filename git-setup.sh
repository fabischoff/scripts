#!/bin/bash

echo "========================================"
echo "    Configuração Automática do Git"
echo "========================================"
echo "Selecione o nível da configuração:"
echo "1) Local  (Apenas para a pasta do projeto atual - PADRÃO)"
echo "2) Global (Para todos os projetos do usuário atual)"
echo "3) System (Para todos os usuários do SO )"

# Mudamos o texto para avisar que o Enter seleciona o padrão
read -p "Digite a opção (1, 2 ou 3) [Enter para Local]: " opcao

# O PULO DO GATO: Se $opcao estiver vazia, define como 1
opcao=${opcao:-1}

# Define a flag baseada na escolha
case $opcao in
    1) ESCOPO="--local" ;;
    2) ESCOPO="--global" ;;
    3) ESCOPO="--system" ;;
    *) echo "❌ Opção inválida. Operação cancelada." ; exit 1 ;;
esac

# Trava de segurança: Se for local, precisa estar dentro de um repositório Git
if [ "$ESCOPO" == "--local" ]; then
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "❌ Erro: Você escolheu Local, mas o diretório atual ($(pwd)) não é um repositório Git."
        echo "Rode 'git init' primeiro e tente novamente."
        exit 1
    fi
fi

# Coleta os dados
echo "----------------------------------------"
read -p "Digite seu Nome: " NOME
read -p "Digite seu E-mail: " EMAIL

echo "----------------------------------------"
echo "Aplicando configurações no nível $ESCOPO..."

# Se for System, precisa de privilégios de root (sudo)
if [ "$ESCOPO" == "--system" ]; then
    sudo git config --system user.name "$NOME"
    sudo git config --system user.email "$EMAIL"
    sudo git config --system core.editor "vim"
    sudo git config --system core.autocrlf input 
    sudo git config --global core.lang en_US
    sudo git config --global init.defaultBranch main

else
    git config $ESCOPO user.name "$NOME"
    git config $ESCOPO user.email "$EMAIL"
    git config $ESCOPO core.editor "vim"
    git config $ESCOPO core.autocrlf input
    git config --global core.lang en_US
    git config --global init.defaultBranch main

fi

echo "✔️  Configuração concluída com sucesso!"
echo "Resumo atual ($ESCOPO):"
git config $ESCOPO --list | grep -E 'user|core.autocrlf'
echo "========================================"
