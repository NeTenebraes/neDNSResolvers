#!/bin/bash

_validate_integrity() {
    local input=$1; local threads=$2; local output=$3
    echo "[*] Capa 2: Validación de integridad (DNSValidator)..."
    dnsvalidator -threads "$threads" -tL "$input" -o "$output" --silent
}

_filter_fast() {
    local input=$1
    local output=$2
    echo "[*] Capa 1: Filtrado masivo (MassDNS)..." >&2
    local tmp_raw=$(mktemp)
    
    # Aseguramos que el dominio se pase correctamente y bajamos la tasa de paquetes (-s) 
    # para evitar que el firewall del VPS bloquee la salida masiva
    echo "google.com" | massdns -r "$input" -t A -o S -w "$tmp_raw" --quiet -s 1000
    
    # Extraer IPs únicas
    awk '{print $5}' "$tmp_raw" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$output"
    rm -f "$tmp_raw"
}

process_and_update_master() {
    local new_candidates=$1
    local master=$2
    local threads=$3
    local temp_dir=$4

    _filter_fast "$new_candidates" "$temp_dir/survivors.txt"

    if [ -s "$temp_dir/survivors.txt" ]; then
        validate_integrity "$temp_dir/survivors.txt" "$threads" "$temp_dir/verified.txt"
        
        if [ -s "$temp_dir/verified.txt" ]; then
            cat "$temp_dir/verified.txt" >> "$master"
            sort -u "$master" -o "$master"
            echo "[+] Master actualizado: $(wc -l < "$master")" >&2
        fi
    else
        echo "[-] Ningún candidato respondió a la prueba de latencia inicial." >&2
    fi
}
