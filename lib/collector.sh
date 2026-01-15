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
    log_status "Comparando RAW contra LIVE para buscar novedades..."
    
    local tmp_vivos=$(mktemp)
    local tmp_new_to_validate=$(mktemp)
    local tmp_validated=$(mktemp)

    # 1. Ver quién está vivo en el RAW acumulado
    sudo masscan -iL "$RAW_FILE" -p53 --rate 10000 --wait 0 2>/dev/null | awk '{print $6}' | sort -u > "$tmp_vivos"

    # 2. FILTRO CRUCIAL: Solo validar lo que NO tenemos en LIVE
    if [[ -s "$LIVE_FILE" ]]; then
        # Extraer IPs de tmp_vivos que NO están en LIVE_FILE
        grep -F -v -f "$LIVE_FILE" "$tmp_vivos" > "$tmp_new_to_validate"
    else
        cat "$tmp_vivos" > "$tmp_new_to_validate"
    fi

    local cant_new=$(wc -l < "$tmp_new_to_validate")
    
    if [ "$cant_new" -gt 0 ]; then
        log_status "Validando $cant_new IPs nuevas detectadas..."
        # Validamos a un temporal, NO al LIVE directamente para no borrarlo
        dnsvalidator -tL "$tmp_new_to_validate" -threads "$threads" -o "$tmp_validated"
        
        # 3. ANEXAR (>>), no sobrescribir
        cat "$tmp_validated" >> "$LIVE_FILE"
        sort -u "$LIVE_FILE" -o "$LIVE_FILE"
        echo -e "    \e[32m✔\e[0m Se añadieron $(wc -l < "$tmp_validated") nuevos servidores a LIVE."
    else
        echo -e "    \e[1;33m[!]\e[0m No hay IPs nuevas; tu lista LIVE ya está al día."
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