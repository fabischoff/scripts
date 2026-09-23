#!/usr/bin/env bash
#
# configura-vpn-detran.sh
# Instala e configura o StrongSwan (IPsec) para o túnel de teletrabalho
# do Detran-RS (gateway Fortinet/Procergs), replicando a configuração
# validada no manual oficial do FortiClient.
#
# Uso:
#   sudo ./configura-vpn-detran.sh
#
# Testado em Kubuntu/Ubuntu 26.04.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configurações — ajuste aqui se necessário
# ---------------------------------------------------------------------------
GATEWAY="vpn.procergs.com.br"
LEFT_ID="detran"
PSK="detran"
XAUTH_USER="ti009632"
XAUTH_PASS="d891g812"

CONN_NAME="tunel-procergs"

# ---------------------------------------------------------------------------
# Checagem de root
# ---------------------------------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
    echo "Erro: execute este script com sudo/root." >&2
    exit 1
fi

echo "==> Instalando StrongSwan e dependências..."
apt update
apt install -y strongswan strongswan-starter strongswan-pki \
    libcharon-extra-plugins libstrongswan-extra-plugins

# ---------------------------------------------------------------------------
# Backup dos arquivos originais, se existirem e ainda não tiverem backup
# ---------------------------------------------------------------------------
for f in /etc/ipsec.conf /etc/ipsec.secrets; do
    if [[ -f "$f" && ! -f "${f}.bak" ]]; then
        cp "$f" "${f}.bak"
        echo "==> Backup criado: ${f}.bak"
    fi
done

# ---------------------------------------------------------------------------
# /etc/ipsec.conf
# ---------------------------------------------------------------------------
echo "==> Escrevendo /etc/ipsec.conf..."
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - gerado por configura-vpn-detran.sh

config setup
        # strictcrlpolicy=yes
        # uniqueids = no

conn ${CONN_NAME}
    keyexchange=ikev1
    aggressive=yes
    authby=xauthpsk
    xauth=client
    xauth_identity=${XAUTH_USER}

    left=%defaultroute
    leftsourceip=%config
    leftid=${LEFT_ID}

    right=${GATEWAY}
    rightid=%any
    rightsubnet=0.0.0.0/0

    ike=aes128-sha1-modp1536,aes256-sha256-modp1536!
    esp=aes128-sha1-modp1536,aes256-sha256-modp1536!

    ikelifetime=24h
    keylife=8h
    dpddelay=30
    dpdtimeout=120
    dpdaction=restart
    keyingtries=1
    forceencaps=yes

    auto=add
EOF

# ---------------------------------------------------------------------------
# /etc/ipsec.secrets
# ---------------------------------------------------------------------------
echo "==> Escrevendo /etc/ipsec.secrets..."
cat > /etc/ipsec.secrets <<EOF
: PSK "${PSK}"
${XAUTH_USER} : XAUTH "${XAUTH_PASS}"
EOF
chmod 600 /etc/ipsec.secrets

# ---------------------------------------------------------------------------
# Recarregar e subir o túnel
# ---------------------------------------------------------------------------
echo "==> Recarregando configuração do StrongSwan..."
ipsec restart
sleep 2
ipsec rereadall
ipsec update

echo "==> Tentando estabelecer o túnel '${CONN_NAME}'..."
if ipsec up "${CONN_NAME}"; then
    echo "==> Túnel estabelecido com sucesso!"
    ipsec statusall
else
    echo "==> Falha ao subir o túnel. Verifique a saída acima ou rode:"
    echo "      sudo ipsec up ${CONN_NAME}"
    echo "    para ver o log detalhado da negociação."
    exit 1
fi
