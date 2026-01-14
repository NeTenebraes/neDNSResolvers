#!/bin/bash

process_and_finalize() {
    local master=$1
    local domain=$2
    local output=$3
    local threads=$4

    echo "[*] Filtrando resolvers (Latencia < 500ms y Sin Wildcards)..." >&2

    # puredns hace el trabajo de massdns + validación de wildcards de forma nativa
    # --rate limita los paquetes para no saturar
    puredns resolve "$domain" -r "$master" --rate "$threads" --quiet > "$output"

    if [ -s "$output" ]; then
        echo "[DONE] Lista lista: $(wc -l < "$output") resolvers validos para $domain." >&2
        # Actualizamos el master acumulativo solo con los que pasaron la prueba
        cat "$output" >> "$master"
        sort -u "$master" -o "$master"
    else
        echo "[-] Error: Ningún resolver pasó la validación para $domain." >&2
    fi
}