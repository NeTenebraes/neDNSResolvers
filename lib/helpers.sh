#!/bin/bash
# /opt/neDNSR/lib/helpers.sh

cleanup() {
    echo -e "\n\n[!] Saliendo y limpiando procesos..." >&2
    pkill -P $$ 2>/dev/null
    exit 1
}

log_status() {
    echo -e "\n\e[1;34m[➜]\e[0m $1" >&2
}

export -f cleanup
export -f log_status