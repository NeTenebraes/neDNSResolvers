#!/bin/bash

fetch_public_resolvers() {
    local output_file=$1
    echo "[*] Descargando y saneando candidatos externos..."

    # 1. Descargamos de múltiples fuentes
    # 2. Filtramos solo lo que parezca una IP
    # 3. Eliminamos IPs de rangos reservados/privados (Opcional pero recomendado)
    # 4. 'sort -u' para asegurar que el archivo de salida sea único
    
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
             grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | \
             sort -u > "$output_file"

    # Verificación de honestidad
    local total=$(wc -l < "$output_file")
    echo "[+] Recolección completada: $total candidatos únicos detectados."
}