#!/bin/bash
MASTER_LIST="/opt/neDNSR/master_resolvers.txt"

fetch_and_merge() {
    echo "[*] Descargando fuentes online..." >&2
    touch "$MASTER_LIST"
    
    # Descarga y limpia en un solo paso
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
    grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | \
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" >> "$MASTER_LIST"

    sort -u "$MASTER_LIST" -o "$MASTER_LIST"
    echo "[+] Master consolidado: $(wc -l < "$MASTER_LIST") IPs." >&2
}
