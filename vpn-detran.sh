#!/bin/bash
CONN=tunel-procergs
DROP=/etc/systemd/resolved.conf.d/detran.conf

case "$1" in
  up)
    sudo mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNS=10.96.2.11 10.96.2.12\nDomains=~detran.reders\n' | sudo tee "$DROP" >/dev/null
    sudo systemctl restart systemd-resolved
    sudo ipsec up "$CONN"
    sudo ip route del default table 220 2>/dev/null || true
    sudo ipsec statusall
    ;;
  down)
    sudo ipsec down "$CONN"
    sudo rm -f "$DROP"
    sudo systemctl restart systemd-resolved
    ;;
  *)
    echo "uso: $0 up|down"; exit 1;;
esac
