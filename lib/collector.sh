#!/bin/bash
MASTER_LIST="/opt/neDNSR/master_resolvers.txt"

fetch_and_merge() {
    echo "[*] Descargando fuentes online..." >&2
    # Crear/limpiar el archivo
    : > "$MASTER_LIST"
    
    # 1. DESCARGA Y LIMPIEZA INICIAL
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
    grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | \
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" >> "$MASTER_LIST"

    # Eliminar duplicados antes de escanear
    sort -u "$MASTER_LIST" -o "$MASTER_LIST"
    echo "[*] Lista bruta consolidada: $(wc -l < "$MASTER_LIST") IPs." >&2

    # 2. FILTRO DE SUPERVIVENCIA (MASSCAN)
    # Filtramos el puerto 53 para no enviarle basura a DNSValidator
    echo "[*] Escaneando puerto 53 con Masscan para identificar servidores activos..." >&2
    
    # Usamos un archivo temporal para el output de masscan
    TMP_SCAN=$(mktemp)
    
    # Ejecutamos masscan (rate 5000 es seguro para la mayoría de redes)
    sudo masscan -iL "$MASTER_LIST" -p53 --rate 5000 --wait 0 2>/dev/null > "$TMP_SCAN"
    
    # Extraemos solo las IPs y sobrescribimos el Master List con los que SÍ están vivos
    awk '{print $6}' "$TMP_SCAN" | sort -u > "$MASTER_LIST"
    
    rm -f "$TMP_SCAN"
    
    echo "[+] Master filtrado (Vivos): $(wc -l < "$MASTER_LIST") IPs." >&2
}