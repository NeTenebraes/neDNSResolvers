#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    log_status "Ranking de velocidad para $target..."

    # Escupe resultados en tiempo real
    cat "$input" | xargs -P "$threads" -I {} sh -c '
        ms=$(dig @{} '$target' +tries=1 +timeout=1 | grep "Query time" | awk "{print \$4}")
        if [ ! -z "$ms" ]; then
            echo -e "\e[32m[+]\e[0m {} | ${ms}ms"
            echo "$ms {}"
        fi
    ' | tee "$tmp_bench"

    # Lógica de recorte para el argumento -top
    if [[ "$limit" == "all" ]]; then
        sort -n "$tmp_bench" | awk '{print $2}' > "$output"
    else
        sort -n "$tmp_bench" | head -n "$limit" | awk '{print $2}' > "$output"
    fi
    
    local final_count=$(wc -l < "$output")
    echo -e "\n\e[1;32m[✔]\e[0m Proceso finalizado. $final_count resolvers guardados en $output"
    rm -f "$tmp_bench"
}