#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    log_status "Iniciando ranking con $threads hilos para $target..."

    # Procesamos las IPs. Usamos printf para evitar problemas con echo -e
    cat "$input" | sort -u | xargs -P "$threads" -I {} sh -c "
        ms=\$(dig @{} $target +tries=1 +timeout=1 | grep 'Query time' | awk '{print \$4}')
        if [ ! -z \"\$ms\" ]; then
            # Esto imprime SOLO en la pantalla del usuario, con colores
            printf \"\e[32m[+]\e[0m {} | \${ms}ms\n\" > /dev/tty
            
            # Esto guarda los datos para procesar en el archivo temporal
            echo \"\$ms {}\"
        fi
    " > "$tmp_bench"

    # Lógica de guardado final (Solo las IPs, ordenadas por velocidad)
    if [[ "$limit" == "all" ]]; then
        sort -n "$tmp_bench" | awk '{print $2}' > "$output"
    else
        sort -n "$tmp_bench" | head -n "$limit" | awk '{print $2}' > "$output"
    fi
    
    # Limpieza de duplicados final en el output por si las moscas
    sort -u "$output" -o "$output"
    
    local final_count=$(wc -l < "$output")
    echo -e "\n\e[1;32m[✔]\e[0m Ranking finalizado. Se han guardado $final_count IPs únicas en $output"
    
    rm -f "$tmp_bench"
}