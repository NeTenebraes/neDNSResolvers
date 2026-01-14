#!/bin/bash

finalize_target_list() {
    local master=$1
    local domain=$2
    local final_output=$3
    local limit=$4
    local tmp_ranked=$(mktemp)

    # Enviamos los mensajes informativos al canal de errores (stderr) para que no ensucien la variable
    echo "[*] Midiendo latencia y filtrando wildcards para: $domain" >&2
    
    # CORRECCIÓN PUREDNS: Usar stdin para un solo dominio
    echo "$domain" | puredns resolve -r "$master" --quiet > "$tmp_ranked"

    if [ "$limit" -gt 0 ] && [ -s "$tmp_ranked" ]; then
        head -n "$limit" "$tmp_ranked" > "$final_output"
    else
        cat "$tmp_ranked" > "$final_output"
    fi

    # Contamos de forma silenciosa
    local count=$(grep -cE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$final_output" 2>/dev/null || echo 0)
    rm -f "$tmp_ranked"
    
    # Única salida al canal estándar (stdout): el número puro
    echo "$count"
}