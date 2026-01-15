#!/bin/bash
# /opt/neDNSR/lib/collector.sh

update_master_raw() {
    log_status "Actualizando base RAW desde fuentes externas..."
    # Añadimos a RAW con >> y limpiamos duplicados
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
    tr -d '\r' | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | \
    grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" >> "$RAW_FILE"
    
    sort -u "$RAW_FILE" -o "$RAW_FILE"
    echo -e "    \e[32m✔\e[0m RAW consolidado: \e[1m$(wc -l < "$RAW_FILE")\e[0m IPs."
}

validate_raw_to_live() {
    local threads=$1
    log_status "Filtrando RAW para encontrar nuevas IPs candidatas..."
    
    local tmp_vivos=$(mktemp)
    local tmp_new_to_validate=$(mktemp)
    local tmp_validated=$(mktemp)

    # 1. Sacamos los que están vivos actualmente en RAW
    sudo masscan -iL "$RAW_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_vivos"

    # 2. ABSTRACCIÓN: Solo validamos los que están vivos PERO que no están ya en LIVE
    if [[ -f "$LIVE_FILE" ]]; then
        # comm -23 extrae líneas que están en tmp_vivos pero NO en LIVE_FILE
        comm -23 "$tmp_vivos" <(sort "$LIVE_FILE") > "$tmp_new_to_validate"
    else
        cat "$tmp_vivos" > "$tmp_new_to_validate"
    fi

    local cant_new=$(wc -l < "$tmp_new_to_validate")
    
    if [ "$cant_new" -gt 0 ]; then
        log_status "Validando $cant_new nuevas IPs con DNSValidator..."
        dnsvalidator -tL "$tmp_new_to_validate" -threads "$threads" -o "$tmp_validated"
        
        # 3. Añadimos lo nuevo al LIVE acumulativo
        cat "$tmp_validated" >> "$LIVE_FILE"
        sort -u "$LIVE_FILE" -o "$LIVE_FILE"
        echo -e "    \e[32m✔\e[0m LIVE actualizado. Total acumulado: \e[1m$(wc -l < "$LIVE_FILE")\e[0m IPs."
    else
        echo -e "    \e[1;33m[!]\e[0m No hay IPs nuevas que validar para LIVE."
    fi

    rm -f "$tmp_vivos" "$tmp_new_to_validate" "$tmp_validated"
}

clean_live_logic() {
    log_status "Saneando lista LIVE (Eliminando caídos)..."
    [[ ! -f "$LIVE_FILE" ]] && return
    
    local tmp_alive=$(mktemp)
    # Re-escaneo de LIVE para asegurar que siguen ahí
    sudo masscan -iL "$LIVE_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_alive"
    
    mv "$tmp_alive" "$LIVE_FILE"
    echo -e "    \e[32m✔\e[0m LIVE activo y real: \e[1m$(wc -l < "$LIVE_FILE")\e[0m"
}