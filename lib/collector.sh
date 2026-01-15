#!/bin/bash
# /opt/neDNSR/lib/collector.sh

update_master_raw() {
    log_status "Actualizando base RAW desde fuentes externas..."
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
    tr -d '\r' | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | \
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" >> "$RAW_FILE"
    
    sort -u "$RAW_FILE" -o "$RAW_FILE"
    echo -e "    \e[32m✔\e[0m RAW consolidado: \e[1m$(wc -l < "$RAW_FILE")\e[0m IPs."
}

validate_raw_to_live() {
    local threads=$1
    log_status "Pre-filtrado Masscan sobre RAW para descartar muertos..."
    
    local tmp_vivos=$(mktemp)
    # Masscan a 10k de rate para limpiar el RAW rápido
    sudo masscan -iL "$RAW_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_vivos"
    
    local cant_vivos=$(wc -l < "$tmp_vivos")
    log_status "Supervivientes: $cant_vivos. Iniciando DNSValidator (Poisoning Check)..."

    if [ "$cant_vivos" -gt 0 ]; then
        # Solo pasamos dnsvalidator a lo que masscan marcó como vivo
        dnsvalidator -tL "$tmp_vivos" -threads "$threads" -o "$LIVE_FILE"
        touch "$LIVE_FILE"
        echo -e "    \e[32m✔\e[0m LIVE actualizado: \e[1m$(wc -l < "$LIVE_FILE")\e[0m IPs seguras."
    else
        echo -e "    \e[31m[!]\e[0m No se detectaron IPs vivas para validar."
    fi
    rm -f "$tmp_vivos"
}

clean_live_logic() {
    log_status "Saneando lista LIVE (Check rápido de supervivencia)..."
    local tmp_alive=$(mktemp)
    sudo masscan -iL "$LIVE_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_alive"
    mv "$tmp_alive" "$LIVE_FILE"
    echo -e "    \e[32m✔\e[0m LIVE activo: \e[1m$(wc -l < "$LIVE_FILE")\e[0m"
}