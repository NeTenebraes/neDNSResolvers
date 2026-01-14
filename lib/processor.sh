#!/bin/bash

# Capa 1: Filtrado masivo por respuesta rápida
filter_fast_responders() {
    local input=$1
    local output=$2
    echo "[*] Capa 1: Filtrado masivo (MassDNS)..."
    
    local tmp_raw=$(mktemp)
    # Disparar a todos los candidatos para ver quién responde a google
    massdns -r "$input" -t A -o S -w "$tmp_raw" --quiet --sndbuf 524288 --rcvbuf 524288 <<< "google.com"
    
    # Extraer IPs únicas que respondieron
    awk '{print $5}' "$tmp_raw" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$output"
    rm -f "$tmp_raw"
}

# Capa 2: Validación de integridad y seguridad
validate_integrity() {
    local input=$1
    local threads=$2
    local output=$3
    echo "[*] Capa 2: Validación de integridad (DNSValidator)..."
    
    dnsvalidator -threads "$threads" -tL "$input" -o "$output" --silent
}

# Función para actualizar el Master List sin duplicados
update_master() {
    local new_valid=$1
    local master=$2
    if [ -s "$new_valid" ]; then
        cat "$new_valid" >> "$master"
        sort -u "$master" -o "$master"
        echo "[+] Master actualizado. Total: $(wc -l < "$master")"
    fi
}