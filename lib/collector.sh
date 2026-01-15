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
    local tmp_vivos=$(mktemp)
    local tmp_new=$(mktemp)
    local tmp_val=$(mktemp) # Temporal para dnsvalidator

    log_status "Paso 1: Detectando IPs vivas en RAW..."
    sudo masscan -iL "$RAW_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_vivos"

    log_status "Paso 2: Filtrando novedades..."
    if [[ -s "$LIVE_FILE" ]]; then
        grep -F -v -x -f "$LIVE_FILE" "$tmp_vivos" > "$tmp_new"
    else
        cat "$tmp_vivos" > "$tmp_new"
    fi

    local n_nuevos=$(wc -l < "$tmp_new")
    if [ "$n_nuevos" -gt 0 ]; then
        log_status "Paso 3: Validando $n_nuevos IPs (Presiona Ctrl+C si quieres saltar al benchmark)..."
        
        # Ejecutamos dnsvalidator
        dnsvalidator -tL "$tmp_new" -threads "$threads" -o "$tmp_val"
        
        # SOLO si dnsvalidator terminó y soltó datos, los movemos a LIVE
        if [[ -s "$tmp_val" ]]; then
            cat "$tmp_val" >> "$LIVE_FILE"
            sort -u "$LIVE_FILE" -o "$LIVE_FILE"
            log_status "Nuevas IPs guardadas en LIVE."
        fi
    fi
    rm -f "$tmp_vivos" "$tmp_new" "$tmp_val"
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