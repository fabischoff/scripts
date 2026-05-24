#!/bin/bash

# Caminho do arquivo de aliases e do backup
ARQUIVO_ALIAS="/etc/profile.d/meus_aliases.sh"
BACKUP_ALIAS="/tmp/meus_aliases.sh.bak"

# Verificação antecipada de privilégios (pede senha do sudo no início, se necessário)
if ! sudo -v &> /dev/null; then
    echo "❌ Erro: Este utilitário precisa de permissões de administrador."
    return 1 2>/dev/null || exit 1
fi

# Garante que o arquivo principal exista
[ ! -f "$ARQUIVO_ALIAS" ] && sudo touch "$ARQUIVO_ALIAS"

ajuda() {
    echo "Uso: source $0 [add|del|list|edit]"
    echo "  add  'nome' 'comando'  - Adiciona/Altera um alias"
    echo "  del  'nome'            - Remove um alias"
    echo "  list                   - Lista os aliases atuais"
    echo "  edit                   - Abre o arquivo no vim para edição manual"
}

fazer_backup() {
    sudo cp "$ARQUIVO_ALIAS" "$BACKUP_ALIAS"
}

case "$1" in
    add)
        if [ -z "$2" ] || [ -z "$3" ]; then ajuda; return 1 2>/dev/null || exit 1; fi

        # Validação de Sintaxe
        if ! bash -c "alias $2='$3'" 2>/dev/null; then
            echo "❌ Erro: A sintaxe do alias '$2' é inválida. Nada alterado."
            return 1 2>/dev/null || exit 1
        fi

        fazer_backup
        sudo sed -i "/alias $2=/d" "$ARQUIVO_ALIAS"
        echo "alias $2='$3'" | sudo tee -a "$ARQUIVO_ALIAS" > /dev/null
        echo "✅ Alias '$2' validado e adicionado. (Backup: $BACKUP_ALIAS)"
        ;;

    del)
        if [ -z "$2" ]; then ajuda; return 1 2>/dev/null || exit 1; fi
        fazer_backup
        sudo sed -i "/alias $2=/d" "$ARQUIVO_ALIAS"
        echo "🗑️  Alias '$2' removido. (Backup: $BACKUP_ALIAS)"
        ;;

    list)
        echo "--- Conteúdo de $ARQUIVO_ALIAS ---"
        # Utiliza cat -n para numerar as linhas facilitando a leitura
        cat -n "$ARQUIVO_ALIAS"
        return 0 2>/dev/null || exit 0
        ;;

    edit)
        fazer_backup
        # Abre o arquivo utilizando o vim
        sudo vim "$ARQUIVO_ALIAS"
        echo "📝 Edição manual concluída. (Backup: $BACKUP_ALIAS)"
        ;;

    *)
        ajuda
        return 1 2>/dev/null || exit 1
        ;;
esac

# Recarga automática na sessão atual
if [ -f "$ARQUIVO_ALIAS" ]; then
    source "$ARQUIVO_ALIAS"
    echo "🔄 Sessão do Kubuntu 26.04 atualizada!"
fi
