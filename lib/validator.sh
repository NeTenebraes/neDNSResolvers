#!/bin/bash

run_integrity_check() {
    local input=$1; local threads=$2; local output=$3
    dnsvalidator -threads "$threads" -tL "$input" -o "$output" --silent
}

run_puredns_validation() {
    local master=$1; local domain=$2; local final_output=$3; local limit=$4
    local tmp_ranked=$(mktemp /tmp/ranked.XXXXXX)

    echo "[*] Filtrando wildcards y midiendo latencia para: $domain"
    
    # Sintaxis corregida para puredns
    puredns resolve -r "$master" --quiet <<< "$domain" > "$tmp_ranked"

    if [ "$limit" -gt 0 ]; then
        head -n "$limit" "$tmp_ranked" > "$final_output"
    else
        mv "$tmp_ranked" "$final_output"
    fi
    rm -f "$tmp_ranked"
}