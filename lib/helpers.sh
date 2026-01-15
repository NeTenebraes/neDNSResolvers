#!/bin/bash
# /opt/neDNSR/lib/helpers.sh

cleanup() {
    echo -e "\n\n[!] Interrupción detectada. Limpiando procesos..." >&2
    pkill -P $$ 2>/dev/null
    exit 1
}

log_status() {
    echo -e "\n\e[1;34m[➜]\e[0m $1" >&2
}

usage() {
    echo -e "\e[1;37mneDNSR - Herramienta de Recolección de Resolvers para Bug Bounty\e[0m"
    echo -e "Uso: neDNSR -d <dominio> [-m <mode>] [-o <archivo>] [-t <hilos>] [-top <numero>] [--update]"
    echo -e "  -d      : Dominio para el benchmark (ej: google.com)"
    echo -e "  -m      : Modo de comparación: \e[32mdirect\e[0m (IP exacta) o \e[35mfull\e[0m (Rango Red + DNSValidator)"
    echo -e "  -o      : Archivo de salida (default: $DEFAULT_OUTPUT)"
    echo -e "  -t      : Número de hilos (default: 200)"
    echo -e "  -top    : Cantidad de mejores DNS a filtrar (default: all)"
    echo -e "  --update: Ingesta nuevas fuentes y re-valida integridad con DNSValidator (RAW -> LIVE)"
    exit 1
}

export -f cleanup
export -f log_status