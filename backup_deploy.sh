# Solicita o usuário de acesso SSH
read -p "Digite o usuário para o acesso SSH: " SSH_USER

# Validação do usuário
if [ -z "$SSH_USER" ]; then
    echo "Erro: Usuário não informado."
    exit 1
fi

# Menu de opções para o ambiente de destino
echo "Selecione o ambiente de origem do dump:"
options=(
    "Produção (detranpaedb05.detran.reders)"
    "Homologação (VM022331.detran.reders)"
    "Desenvolvimento (vm022330.detran.reders)"
)

select opt in "${options[@]}"; do
    case $REPLY in
        1)
            SSH_HOST="detranpaedb05.detran.reders"
            AMBIENTE="Produção"
            break
            ;;
        2)
            SSH_HOST="VM022331.detran.reders"
            AMBIENTE="Homologação"
            break
            ;;
        3)
            SSH_HOST="vm022330.detran.reders"
            AMBIENTE="Desenvolvimento"
            break
            ;;
        *)
            echo "Opção inválida. Por favor, escolha de 1 a 3."
            ;;
    esac
done

echo "Ambiente selecionado: $AMBIENTE ($SSH_HOST)"

# Testa a conexão SSH antes de prosseguir
echo "Testando conexão SSH com $SSH_USER@$SSH_HOST..."
if ! ssh -q -o ConnectTimeout=5 "$SSH_USER@$SSH_HOST" "exit"; then
    echo "Erro: Não foi possível conectar via SSH em $SSH_USER@$SSH_HOST"
    exit 1
fi

echo "Conexão SSH estabelecida com sucesso!"

# Solicita o nome da base de dados
read -p "Digite o nome da base de dados (Ex: sgrhweb ): " DB_NAME

# Solicita o nome da tabela
read -p "Digite o nome da tabela: " DB_TABLE

# Validação dos campos do banco de dados
if [ -z "$DB_NAME" ] || [ -z "$DB_TABLE" ]; then
    echo "Erro: Base de dados ou tabela não informadas."
    exit 1
fi

echo "Iniciando o dump da tabela '$DB_TABLE' na base '$DB_NAME' no servidor remoto..."

# Executa o pg_dump dinamicamente como usuário postgres
#ssh -t "$SSH_USER@$SSH_HOST" "sudo -u postgres pg_dump -t $DB_TABLE -d $DB_NAME > /tmp/${DB_TABLE}.sql"
# Executa o pg_dump dinamicamente como usuário postgres, silenciando avisos de locale
ssh -t "$SSH_USER@$SSH_HOST" "LC_ALL=C sudo -u postgres pg_dump -t $DB_TABLE -d $DB_NAME > /tmp/${DB_TABLE}.sql"
# Valida se o comando remoto terminou com sucesso
if [ $? -eq 0 ]; then
    echo "Dump realizado com sucesso em /tmp/${DB_TABLE}.sql no servidor remoto."
else
    echo "Erro ao realizar o dump no servidor remoto."
    exit 1
fi

echo "Transferindo o arquivo de backup diretamente entre os servidores..."

# Menu de opções para o ambiente de IMPORTAÇÃO (Destino do Restore)
echo ""
echo "Selecione o ambiente no qual o backup será IMPORTADO:"
options_import=(
    "Produção (detranpaedb05.detran.reders)"
    "Homologação (VM022331.detran.reders)"
    "Desenvolvimento (vm022330.detran.reders)"
)

select opt_imp in "${options_import[@]}"; do
    case $REPLY in
        1)
            IMPORT_HOST="detranpaedb05.detran.reders"
            IMPORT_AMBIENTE="Produção"
            break
            ;;
        2)
            IMPORT_HOST="VM022331.detran.reders"
            IMPORT_AMBIENTE="Homologação"
            break
            ;;
        3)
            IMPORT_HOST="vm022330.detran.reders"
            IMPORT_AMBIENTE="Desenvolvimento"
            break
            ;;
        *)
            echo "Opção inválida. Por favor, escolha de 1 a 3."
            ;;
    esac
done

echo "Ambiente de importação selecionado: $IMPORT_AMBIENTE ($IMPORT_HOST)"


# Executa o SCP de dentro do servidor de origem para o servidor de destino
ssh -t "$SSH_USER@$SSH_HOST" "LC_ALL=C scp /tmp/${DB_TABLE}.sql $SSH_USER@$IMPORT_HOST:/tmp/"

# Valida se a transferência ocorreu sem erros
if [ $? -eq 0 ]; then
    echo "Arquivo /tmp/${DB_TABLE}.sql transferido com sucesso para o servidor $IMPORT_HOST!"
else
    echo "Erro ao transferir o arquivo para o servidor de destino."
    exit 1
fi


echo ""
# Solicita a base de dados de destino para o restore
read -p "Digite o nome da base de dados de destino (Ex: sgrhweb): " IMPORT_DB_NAME

# Validação do banco de destino
if [ -z "$IMPORT_DB_NAME" ]; then
    echo "Erro: Base de dados de destino não informada."
    exit 1
fi

echo "Iniciando a importação do backup no ambiente de $IMPORT_AMBIENTE..."

# Conecta no servidor de destino e executa o restore como usuário postgres
ssh -t "$SSH_USER@$IMPORT_HOST" "LC_ALL=C sudo -u postgres psql -d $IMPORT_DB_NAME -p 5432 < /tmp/${DB_TABLE}.sql"

# Valida se a importação terminou com sucesso
if [ $? -eq 0 ]; then
    echo "Importação realizada com sucesso no banco '$IMPORT_DB_NAME' em $IMPORT_AMBIENTE!"
else
    echo "Erro ao realizar a importação no servidor de destino."
    exit 1
fi
