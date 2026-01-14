#!/bin/bash

# Función para descargar y filtrar candidatos únicos que no están en el Master
fetch_RAW() {
    local master_file=$1
    local output_file=$2
    local temp_raw=$(mktemp)

    echo "[*] Descargando candidatos de fuentes externas..."

    # 1. Descarga y normalización básica
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
             grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | \
             grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" | \
             sort -u > "$temp_raw"

    # 2. Comparación lógica (Aislamiento de novedades)
    # Si el Master existe, extraemos solo lo que no conocemos
    if [ -f "$master_file" ] && [ -s "$master_file" ]; then
        comm -23 "$temp_raw" <(sort -u "$master_file") > "$output_file"
    else
        mv "$temp_raw" "$output_file"
    fi

    local total=$(wc -l < "$output_file")
    echo "[+] Recolección finalizada: $total candidatos nuevos para validar."
    
    rm -f "$temp_raw"
}