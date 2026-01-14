#!/bin/bash
# /opt/neDNSR/lib/collector.sh

MASTER_LIST="/opt/neDNSR/master_resolvers.txt"
VIVOS_LIST="/opt/neDNSR/vivos.txt"

fetch_and_merge() {
    log_status "Iniciando descarga de fuentes online..."    
   
    # Descarga y concatena con lo que ya existe, luego limpia
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
    tr -d '\r' | \
    grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | \
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" >> "$MASTER_LIST"

    # Elimina duplicados de toda la vida
    sort -u "$MASTER_LIST" -o "$MASTER_LIST"
    
    echo -e "    \e[32m✔\e[0m IPs brutas consolidadas: \e[1m$(wc -l < "$MASTER_LIST")\e[0m"
    
    # 2. FILTRO DE SUPERVIVENCIA (MASSCAN)
    log_status "Escaneando puerto 53 con Masscan para detectar servidores activos..."
    
    local tmp_scan=$(mktemp)
    
    # Ejecutamos masscan: usamos sudo solo si es necesario, rate 10000 para velocidad
    sudo masscan -iL "$MASTER_LIST" -p53 --rate 10000 --wait 0 2>/dev/null > "$tmp_scan"
    
    # Extraemos IPs y guardamos en VIVOS_LIST (No sobrescribimos el Master para no perder la fuente)
    awk '{print $6}' "$tmp_scan" | sort -u > "$VIVOS_LIST"
    rm -f "$tmp_scan"
    
    local vivos_count=$(wc -l < "$VIVOS_LIST")
    echo -e "    \e[32m✔\e[0m Servidores DNS activos (Puerto 53 Abierto): \e[1m$vivos_count\e[0m"
    
    # Validación de seguridad: Si no hay vivos, detenemos el script
    if [ "$vivos_count" -eq 0 ]; then
        echo -e "\e[1;31m[!] ERROR: No se detectaron DNS activos. Revisa tu conexión o firewall.\e[0m"
        exit 1
    fi

    log_status "Preparando lista para validación de integridad (DNSValidator)..."
}