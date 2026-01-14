#!/bin/bash

# Validación lenta de integridad (solo para nuevos)
run_integrity_check() {
    local input=$1
    local threads=$2
    local output=$3
    # dnsvalidator asegura que los resolvers no estén envenenados
    dnsvalidator -threads "$threads" -tL "$input" -o "$output" --silent
}

# Validación rápida, Wildcards y Ranking
run_puredns_validation() {
    local master=$1
    local domain=$2
    local final_output=$3
    local limit=$4
    
    local tmp_ranked=$(mktemp /tmp/ranked.XXXXXX)

    echo "[*] Filtrando wildcards y midiendo latencia para: $domain"
    
    # PureDNS filtra wildcards de forma nativa y prioriza los más rápidos
    puredns resolve "$domain" -r "$master" --quiet > "$tmp_ranked"

    if [ "$limit" -gt 0 ]; then
        echo "[+] Extrayendo el Top $limit de servidores más veloces..."
        head -n "$limit" "$tmp_ranked" > "$final_output"
    else
        mv "$tmp_ranked" "$final_output"
    fi

    rm -f "$tmp_ranked"
}