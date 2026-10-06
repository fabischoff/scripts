#!/usr/bin/env bash
#
# instalar-vpn-detran.sh
# Instala o StrongSwan e grava a configuração do túnel. Rodar UMA VEZ
# por máquina. Para subir/derrubar o túnel no dia a dia, use vpn.sh.
#
# Uso:
#   sudo ./instalar-vpn-detran.sh

set -euo pipefail

GATEWAY="vpn.procergs.com.br"
LEFT_ID="detran"
PSK="detran"
XAUTH_USER="ti009632"
XAUTH_PASS="d891g812"
CONN_NAME="tunel-procergs"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Erro: execute este script com sudo/root." >&2
    exit 1
fi

echo "==> Instalando StrongSwan e dependências..."
apt update
apt install -y strongswan strongswan-starter strongswan-pki \
    libcharon-extra-plugins libstrongswan-extra-plugins

for f in /etc/ipsec.conf /etc/ipsec.secrets; do
    if [[ -f "$f" && ! -f "${f}.bak" ]]; then
        cp "$f" "${f}.bak"
        echo "==> Backup criado: ${f}.bak"
    fi
done

echo "==> Escrevendo /etc/ipsec.conf..."
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - gerado por instalar-vpn-detran.sh

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
    rightsubnet=10.0.0.0/8

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

echo "==> Escrevendo /etc/ipsec.secrets..."
cat > /etc/ipsec.secrets <<EOF
: PSK "${PSK}"
${XAUTH_USER} : XAUTH "${XAUTH_PASS}"
EOF
chmod 600 /etc/ipsec.secrets

echo "==> Recarregando StrongSwan..."
ipsec restart
sleep 2
ipsec rereadall
ipsec update

echo "==> Instalação concluída. Use ./vpn.sh up para conectar."
