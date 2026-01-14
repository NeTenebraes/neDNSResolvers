#!/bin/bash

# --- Configuración ---
MASTER_LIST="/opt/neDNSR/master_resolvers.txt"
DOMAIN_CHECK="google.com"

# 1. Función de Recolección Bruta (RAW)
# Descarga, une y elimina duplicados sintácticos
fetch_and_merge() {
    echo "[*] Fase 1: Recolectando candidatos RAW..."
    
    # Creamos el master si no existe
    touch "$MASTER_LIST"

    # Descarga directa y append al master
    # Fuentes: Trickest + Public-DNS (puedes añadir más aquí)
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt >> "$MASTER_LIST"

    # Limpieza: 
    # 1. Extraer solo IPs válidas
    # 2. Eliminar IPs locales/privadas
    # 3. Unificar (sort -u)
    sed -i -E '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/!d' "$MASTER_LIST"
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" "$MASTER_LIST" | sort -u -o "$MASTER_LIST"

    echo "[+] Master consolidado (bruto): $(wc -l < "$MASTER_LIST") IPs."
}

# 2. Función de Verificación de Vida (Live Check)
# Filtra el Master y SOLO deja los que responden actualmente
validate_alive() {
    local threads=${1:-100}
    local temp_live=$(mktemp)

    echo "[*] Fase 2: Validando supervivencia..."

    # 1. Usamos un archivo temporal para el input de nombres para evitar líos de stdin
    echo "google.com" > "$temp_live.name"

    # 2. Ejecutamos MassDNS. Usamos -o L que es el formato más estable (IP_RESOLVER IP_RESPUESTA)
    massdns -r "$MASTER_LIST" -t A -s "$threads" -o L "$temp_live.name" --quiet > "$temp_live.out"

    # 3. Extraemos SOLO la IP del resolver (columna 1)
    awk '{print $1}' "$temp_live.out" | sort -u > "$temp_live.final"

    # 4. VALIDACIÓN CRÍTICA: Solo sobreescribir si encontramos algo
    if [ -s "$temp_live.final" ]; then
        mv "$temp_live.final" "$MASTER_LIST"
        echo "[DONE] Master actualizado: $(wc -l < "$MASTER_LIST") resolvers vivos."
    else
        echo "[-] Error: El filtrado devolvió 0 vivos. Se mantiene la lista anterior para evitar vaciar el archivo."
    fi

    # Limpieza de basura temporal
    rm -f "$temp_live" "$temp_live.name" "$temp_live.out" "$temp_live.final"
}

# 3. Función principal (Orquestador del Collector)
run_collector() {
    local threads=$1
    fetch_and_merge
    validate_alive "$threads"
}