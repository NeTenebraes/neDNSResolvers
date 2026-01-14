#!/bin/bash

finalize_target_list() {
    local master=$1
    local domain=$2
    local final_output=$3
    local limit=$4
    local tmp_ranked=$(mktemp)

    # Enviamos el mensaje a stderr (>&2) para no ensuciar el valor de retorno
    echo "[*] Midiendo latencia y filtrando wildcards para: $domain" >&2
    
    # CORRECCIÓN PUREDNS: Le pasamos el dominio vía stdin
    echo "$domain" | puredns resolve -r "$master" --quiet > "$tmp_ranked"

    if [ "$limit" -gt 0 ] && [ -s "$tmp_ranked" ]; then
        head -n "$limit" "$tmp_ranked" > "$final_output"
    else
        cat "$tmp_ranked" > "$final_output"
    fi

    local count=$(grep -cE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$final_output" 2>/dev/null || echo 0)
    rm -f "$tmp_ranked"
    
    # Única salida a stdout
    echo "$count"
}