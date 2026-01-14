#!/bin/bash

# Capa 1: Filtrado rápido de supervivencia
# Captura IPs activas sin que las estadísticas de MassDNS ensucien la salida
_filter_fast() {
    local input=$1
    local output=$2
    
    # --quiet: Fundamental para que el conteo no falle
    # -s 500: Balance entre velocidad y estabilidad
    massdns -r "$input" -t A -o S -s 500 --quiet <<< "google.com" | \
    awk '{print $NF}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$output"
}

# Orquestador del procesamiento de nuevos candidatos
process_and_update_master() {
    local only_new=$1
    local master=$2
    local threads=$3
    local temp_dir=$4
    local survivors="$temp_dir/survivors.txt"
    local verified="$temp_dir/verified.txt"

    # Ejecuta el filtrado inicial
    _filter_fast "$only_new" "$survivors"

    # Verifica si el archivo de sobrevivientes tiene contenido
    if [ -s "$survivors" ]; then
        local count_s=$(wc -l < "$survivors")
        echo "[+] $count_s candidatos vivos. Iniciando validación profunda (DNSValidator)..."
        
        # Capa 2: DNSValidator (Elimina Wildcards y basura técnica)
        # Usamos la ruta absoluta al binario que instalamos en /opt
        /usr/local/bin/dnsvalidator -threads "$threads" -tL "$survivors" -o "$verified" --silent
        
        if [ -s "$verified" ]; then
            cat "$verified" >> "$master"
            sort -u "$master" -o "$master"
            echo "[DONE] Master actualizado. Total de resolvers: $(wc -l < "$master")"
        else
            echo "[!] DNSValidator filtró todos los candidatos (posibles falsos positivos)."
        fi
    else
        echo "[-] Ningún candidato respondió a la prueba de latencia inicial en Capa 1."
    fi
}