#!/bin/bash

# --- Función Pública (La que usa el orquestador) ---
process_and_update_master() {
    local new_candidates=$1
    local master=$2
    local threads=$3
    local temp_dir=$4

    # 1. Capa 1: Machete
    _filter_fast "$new_candidates" "$temp_dir/survivors.txt"

    # 2. Capa 2: Bisturí (Solo si sobrevivieron a la Capa 1)
    if [ -s "$temp_dir/survivors.txt" ]; then
        _validate_integrity "$temp_dir/survivors.txt" "$threads" "$temp_dir/verified.txt"
        
        # 3. Actualización atómica del Master
        if [ -s "$temp_dir/verified.txt" ]; then
            cat "$temp_dir/verified.txt" >> "$master"
            sort -u "$master" -o "$master"
            echo "[+] Master actualizado: $(wc -l < "$master") resolvers totales."
        else
            echo "[-] Ningún candidato superó las pruebas de integridad."
        fi
    else
        echo "[-] Ningún candidato respondió a la prueba de latencia inicial."
    fi
}


# --- Funciones Internas ---
_filter_fast() {
    local input=$1; local output=$2
    echo "[*] Capa 1: Filtrado masivo (MassDNS)..."
    local tmp_raw=$(mktemp)
    
    massdns -r "$input" -t A -o S -w "$tmp_raw" --quiet --sndbuf 524288 --rcvbuf 524288 <<< "google.com"
    awk '{print $5}' "$tmp_raw" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$output"
    rm -f "$tmp_raw"
}

_validate_integrity() {
    local input=$1; local threads=$2; local output=$3
    echo "[*] Capa 2: Validación de integridad (DNSValidator)..."
    dnsvalidator -threads "$threads" -tL "$input" -o "$output" --silent
}