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

    echo "[*] Fase 2: Verificando supervivencia (MassDNS) @ $threads pps..."

    # Ejecución de MassDNS sobre el mismo Master
    # -s: Tasa de paquetes (ajusta según tu conexión de Arch)
    # -o S: Output simple
    massdns -r "$MASTER_LIST" -t A -o S -s "$threads" --quiet <<< "$DOMAIN_CHECK" | \
    awk '{print $NF}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$temp_live"

    # Reemplazo atómico: El Master ahora solo contiene lo que respondió
    if [ -s "$temp_live" ]; then
        mv "$temp_live" "$MASTER_LIST"
        echo "[DONE] Master refinado: $(wc -l < "$MASTER_LIST") resolvers vivos."
    else
        echo "[-] Error: Ningún resolver respondió. Manteniendo Master previo para evitar pérdida total."
        rm -f "$temp_live"
    fi
}

# 3. Función principal (Orquestador del Collector)
run_collector() {
    local threads=$1
    fetch_and_merge
    validate_alive "$threads"
}