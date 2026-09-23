#!/usr/bin/env bash
#
# maquinas-detran.sh — adiciona hosts internos do Detran ao /etc/hosts
# de forma interativa, sempre abaixo do comentário marcador.
#
# Uso:
#   sudo ./maquinas-detran.sh          # pergunta host e IP, adiciona
#   sudo ./maquinas-detran.sh limpar   # remove tudo abaixo do marcador

set -euo pipefail

MARCADOR="######## Máquinas Detran ####"
HOSTS_FILE="/etc/hosts"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Erro: execute este script com sudo/root." >&2
    exit 1
fi

if [[ "${1:-}" == "limpar" ]]; then
    if grep -qF "${MARCADOR}" "${HOSTS_FILE}"; then
        # Mantém tudo até o marcador (inclusive), remove tudo depois
        sed -i "/^$(printf '%s' "${MARCADOR}" | sed 's/[.[\*^$/]/\\&/g')$/q" "${HOSTS_FILE}"
        echo "==> Todas as entradas abaixo do marcador foram removidas."
    else
        echo "==> Nenhum marcador encontrado, nada para limpar."
    fi
    exit 0
fi

read -rp "Nome do host (ex: dt117092.detran.reders): " host
read -rp "IP: " ip

if [[ -z "${host}" || -z "${ip}" ]]; then
    echo "Erro: host e IP não podem ficar em branco." >&2
    exit 1
fi

if ! grep -qF "${MARCADOR}" "${HOSTS_FILE}"; then
    {
        echo ""
        echo "${MARCADOR}"
    } >> "${HOSTS_FILE}"
    echo "==> Marcador criado em ${HOSTS_FILE}."
fi

echo "${ip}   ${host}" >> "${HOSTS_FILE}"
echo "==> Adicionado: ${ip} -> ${host}"
