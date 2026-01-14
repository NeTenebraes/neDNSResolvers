#!/bin/bash

# Función para filtrar por latencia y descartar wildcards
# Uso: finalize_target_list "$MASTER_LIST" "$DOMAIN" "$OUTPUT" "$TOP_N"
finalize_target_list() {
    local master=$1
    local domain=$2
    local final_output=$3
    local limit=$4
    local tmp_ranked=$(mktemp)

    echo "[*] Midiendo latencia y filtrando wildcards para: $domain"
    
    # 1. Resolución y Ranking con PureDNS
    # Usamos resolve para verificar que los resolvers del Master responden al target
    puredns resolve "$domain" -r "$master" --quiet > "$tmp_ranked"

    # 2. Aplicar límite (TOP N) si se solicita
    if [ "$limit" -gt 0 ] && [ -s "$tmp_ranked" ]; then
        head -n "$limit" "$tmp_ranked" > "$final_output"
    else
        cat "$tmp_ranked" > "$final_output"
    fi

    # 3. Verificación de integridad de la salida (Conteo Real)
    local count=$(grep -cE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$final_output" 2>/dev/null || echo 0)
    
    rm -f "$tmp_ranked"
    
    # Retornamos el conteo para que el orquestador lo use
    echo "$count"
}