#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    log_status "Iniciando ranking con $threads hilos para $target..."

    # 1. Benchmark: Aseguramos que el output sea "MS IP" sin basura
    cat "$input" | sort -u | xargs -P "$threads" -I {} sh -c "
        ms=\$(dig @{} $target +tries=1 +timeout=1 | grep 'Query time' | awk '{print \$4}')
        if [ ! -z \"\$ms\" ] && [ \"\$ms\" -gt 0 ]; then
            printf \"\e[32m[+]\e[0m {} | \${ms}ms\n\" > /dev/tty
            echo \"\$ms {}\"
        fi
    " > "$tmp_bench"

    # 2. El truco: Usar 'sort -g' (general numeric) y limpiar el output
    # Filtramos líneas vacías y ordenamos por la primera columna numéricamente
    if [[ "$limit" == "all" ]]; then
        sort -g "$tmp_bench" | awk '{print $2}' | grep -v '^$' > "$output"
    else
        sort -g "$tmp_bench" | head -n "$limit" | awk '{print $2}' | grep -v '^$' > "$output"
    fi
    
    # DEBUG: Verificamos los 3 mejores en pantalla
    echo -e "\n\e[1;33m[!] Verificando los 3 mejores:\e[0m"
    head -n 3 "$output"

    local final_count=$(wc -l < "$output")
    echo -e "\n\e[1;32m[✔]\e[0m Ranking finalizado. Se guardaron $final_count IPs."
    
    rm -f "$tmp_bench"
}
